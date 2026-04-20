//
//  ContentViewModel.swift
//  Video Downloader
//

import SwiftUI
import Photos
import Combine
import UserNotifications
import LoadifyEngine

@MainActor
class ContentViewModel: NSObject, ObservableObject {
    @Published var url: String = ""
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var selectedQuality: String = Constants.UI.defaultQuality
    
    // Smart Suggestion State
    @Published var detectedURL: String? = nil
    @Published var detectedPlatform: String = ""
    @Published var showSuggestion: Bool = false
    
    let qualities = Constants.UI.qualities
    
    private let client = LoadifyClient()
    
    // Verified fallback base URLs
    private let fallbackHosts = Constants.API.cobaltHosts
    
    private var backgroundSession: URLSession?
    private var activeDownloadURL: URL?

    override init() {
        super.init()
        setupNotifications()
        
        let config = URLSessionConfiguration.background(withIdentifier: Constants.Config.backgroundSessionIdentifier)
        config.sessionSendsLaunchEvents = true
        
        // --- Optimizations for Speed ---
        config.isDiscretionary = false 
        config.waitsForConnectivity = true
        
        // Priority Network Service Type
        config.networkServiceType = .responsiveData
        
        // Increase concurrent connections for the background session
        config.httpMaximumConnectionsPerHost = Constants.Config.httpMaximumConnectionsPerHost
        
        // Allow all network types
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        self.backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("DEBUG: Notification permission granted.")
            } else if let error = error {
                print("DEBUG: Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = Constants.Messages.notificationTitle
        content.body = Constants.Messages.notificationBody
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Error scheduling notification: \(error)")
            }
        }
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func startProcess() {
        guard !url.isEmpty else { return }
        
        triggerHaptic(.light)
        isDownloading = true
        statusMessage = Constants.Messages.analyzingLink
        downloadProgress = 0.0
        
        Task {
            do {
                // Try LoadifyEngine first
                try await processWithLoadify()
            } catch {
                print("DEBUG: Engine Error: \(error)")
                statusMessage = Constants.Messages.engineIssueFallback
                // Fallback to manual Cobalt API calls
                await tryFallbackAPI()
            }
        }
    }

    private func processWithLoadify() async throws {
        let details = try await client.fetchVideoDetails(for: url)
        statusMessage = Constants.Messages.downloadingFrom.replacingOccurrences(of: "%s", with: details.platform.rawValue)
        
        guard let videoURL = URL(string: details.video.url) else {
            throw URLError(.badURL)
        }
        
        startBackgroundDownload(from: videoURL)
    }

    private func tryFallbackAPI() async {
        for host in fallbackHosts {
            let paths = Constants.API.apiEndpoints
            for path in paths {
                let endpoint = host + path
                do {
                    let displayHost = host.replacingOccurrences(of: "https://", with: "")
                    statusMessage = Constants.Messages.connectingTo.replacingOccurrences(of: "%s", with: displayHost)
                    
                    let downloadLink = try await fetchFromCobalt(endpoint: endpoint)
                    
                    statusMessage = Constants.Messages.downloadingFile
                    guard let dlURL = URL(string: downloadLink) else { continue }
                    
                    startBackgroundDownload(from: dlURL)
                    return // Task handed over to background session
                } catch {
                    print("DEBUG: Fallback to \(endpoint) failed: \(error)")
                    continue
                }
            }
        }
        
        handleFinalError(message: Constants.Messages.allServicesUnavailable)
    }

    private func fetchFromCobalt(endpoint: String) async throws -> String {
        guard let apiUrl = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = Constants.API.httpMethodPost
        request.timeoutInterval = Constants.Config.requestTimeout
        
        request.addValue(Constants.API.applicationJson, forHTTPHeaderField: Constants.API.contentTypeHeader)
        request.addValue(Constants.API.applicationJson, forHTTPHeaderField: Constants.API.acceptHeader)
        
        let body: [String: Any] = [
            Constants.API.bodyKeyUrl: url,
            Constants.API.bodyKeyVideoQuality: selectedQuality,
            Constants.API.bodyKeyDownloadMode: Constants.API.downloadModeTunnel,
            Constants.API.bodyKeyVCodec: Constants.API.vCodecH264,
            Constants.API.bodyKeyAFormat: Constants.API.aFormatMp3,
            Constants.API.bodyKeyFilenameStyle: Constants.API.filenameStylePretty
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == Constants.Config.defaultStatusCode else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(FallbackAPIResponse.self, from: data)
        
        if let downloadUrl = apiResponse.url, !downloadUrl.isEmpty { return downloadUrl }
        
        if let status = apiResponse.status, status == Constants.API.statusError {
            throw NSError(domain: Constants.Config.errorDomain, code: Constants.Config.errorCode, userInfo: [NSLocalizedDescriptionKey: apiResponse.text ?? "Unknown API Error"])
        }
        
        throw URLError(.fileDoesNotExist)
    }

    private func startBackgroundDownload(from url: URL) {
        self.activeDownloadURL = url
        let task = backgroundSession?.downloadTask(with: url)
        task?.resume()
    }

    func finalizeDownload(localURL: URL) async throws {
        statusMessage = Constants.Messages.savingToGallery
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
        }
        statusMessage = Constants.Messages.successfullySaved
        triggerNotificationHaptic(.success)
        isDownloading = false
        url = ""
        // No need to manually remove here if it's a tmp file from downloadTask, 
        // but we'll be safe
        try? FileManager.default.removeItem(at: localURL)
    }

    private func handleFinalError(message: String) {
        statusMessage = Constants.Messages.processFailed
        triggerNotificationHaptic(.error)
        isDownloading = false
        alertTitle = Constants.Messages.downloadFailed
        alertMessage = message
        showAlert = true
    }

    // MARK: - Smart Magic Paste Logic
    
    func checkClipboard() {
        guard let clipboardString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardString.isEmpty else { return }
        
        // Don't suggest if it's the same URL already in the field or currently being downloaded
        guard clipboardString != self.url else { return }
        
        let lowercased = clipboardString.lowercased()
        var platform = ""
        
        if lowercased.contains("instagram.com") {
            platform = Constants.UI.instagramName
        } else if lowercased.contains("facebook.com") || lowercased.contains("fb.watch") {
            platform = Constants.UI.facebookName
        } else if lowercased.contains("tiktok.com") {
            platform = "TikTok"
        }
        
        if !platform.isEmpty {
            withAnimation(.spring()) {
                self.detectedURL = clipboardString
                self.detectedPlatform = platform
                self.showSuggestion = true
            }
        }
    }
    
    func useDetectedURL() {
        guard let urlToUse = detectedURL else { return }
        
        withAnimation(.spring()) {
            self.url = urlToUse
            self.showSuggestion = false
            self.detectedURL = nil
        }
        
        // Start processing immediately
        triggerHaptic(.medium)
        startProcess()
    }
    
    func dismissSuggestion() {
        withAnimation(.spring()) {
            self.showSuggestion = false
            self.detectedURL = nil
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension ContentViewModel: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        Task { @MainActor in
            self.downloadProgress = progress
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move file to a permanent temporary location because 'location' is deleted after this method
        let fileManager = FileManager.default
        let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            
            Task { @MainActor in
                self.downloadProgress = Constants.Config.maxDownloadProgress
                do {
                    try await self.finalizeDownload(localURL: destinationURL)
                    self.sendCompletionNotification() // Show completion banner
                } catch {
                    self.handleFinalError(message: String(format: Constants.Messages.failedToSaveVideo, error.localizedDescription))
                }
            }
        } catch {
            Task { @MainActor in
                self.handleFinalError(message: Constants.Messages.failedToProcessFile)
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("DEBUG: Background task completed with error: \(error)")
            Task { @MainActor in
                self.handleFinalError(message: error.localizedDescription)
            }
        }
    }
}

struct FallbackAPIResponse: Codable {
    let status: String?
    let url: String?
    let text: String?
}
