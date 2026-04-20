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
    @Published var selectedQuality: String = "360"
    
    let qualities = ["360", "480", "720", "1080", "max"]
    
    private let client = LoadifyClient()
    
    // Verified fallback base URLs
    private let fallbackHosts = [
        "https://cobalt.canine.tools",
        "https://cobalt.meowing.de",
        "https://cobalt.sh",
        "https://cobalt.inst.moe"
    ]
    
    private var backgroundSession: URLSession?
    private var activeDownloadURL: URL?

    override init() {
        super.init()
        setupNotifications()
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.video.downloader.background")
        config.sessionSendsLaunchEvents = true
        
        // --- Optimizations for Speed ---
        config.isDiscretionary = false 
        config.waitsForConnectivity = true
        
        // Priority Network Service Type
        config.networkServiceType = .responsiveData
        
        // Increase concurrent connections for the background session
        config.httpMaximumConnectionsPerHost = 6
        
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
        content.title = "Download Complete"
        content.body = "Your video has been successfully saved to the Gallery."
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
        statusMessage = "Analyzing link..."
        downloadProgress = 0.0
        
        Task {
            do {
                // Try LoadifyEngine first
                try await processWithLoadify()
            } catch {
                print("DEBUG: Engine Error: \(error)")
                statusMessage = "Engine issue. Trying fallback..."
                // Fallback to manual Cobalt API calls
                await tryFallbackAPI()
            }
        }
    }

    private func processWithLoadify() async throws {
        let details = try await client.fetchVideoDetails(for: url)
        statusMessage = "Downloading from \(details.platform)..."
        
        guard let videoURL = URL(string: details.video.url) else {
            throw URLError(.badURL)
        }
        
        startBackgroundDownload(from: videoURL)
    }

    private func tryFallbackAPI() async {
        for host in fallbackHosts {
            let paths = ["/", "/api/json"]
            for path in paths {
                let endpoint = host + path
                do {
                    let displayHost = host.replacingOccurrences(of: "https://", with: "")
                    statusMessage = "Connecting to \(displayHost)..."
                    
                    let downloadLink = try await fetchFromCobalt(endpoint: endpoint)
                    
                    statusMessage = "Downloading file..."
                    guard let dlURL = URL(string: downloadLink) else { continue }
                    
                    startBackgroundDownload(from: dlURL)
                    return // Task handed over to background session
                } catch {
                    print("DEBUG: Fallback to \(endpoint) failed: \(error)")
                    continue
                }
            }
        }
        
        handleFinalError(message: "All download services are currently unavailable. Please try again later.")
    }

    private func fetchFromCobalt(endpoint: String) async throws -> String {
        guard let apiUrl = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "url": url,
            "videoQuality": selectedQuality,
            "downloadMode": "tunnel",  // Force server-side processing for speed on iOS
            "vCodec": "h264",          // Use efficient codec
            "aFormat": "mp3",          // Stable audio format
            "filenameStyle": "pretty"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(FallbackAPIResponse.self, from: data)
        
        if let downloadUrl = apiResponse.url, !downloadUrl.isEmpty { return downloadUrl }
        
        if let status = apiResponse.status, status == "error" {
            throw NSError(domain: "Cobalt", code: 400, userInfo: [NSLocalizedDescriptionKey: apiResponse.text ?? "Unknown API Error"])
        }
        
        throw URLError(.fileDoesNotExist)
    }

    private func startBackgroundDownload(from url: URL) {
        self.activeDownloadURL = url
        let task = backgroundSession?.downloadTask(with: url)
        task?.resume()
    }

    func finalizeDownload(localURL: URL) async throws {
        statusMessage = "Saving to Gallery..."
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
        }
        statusMessage = "Successfully saved!"
        triggerNotificationHaptic(.success)
        isDownloading = false
        url = ""
        // No need to manually remove here if it's a tmp file from downloadTask, 
        // but we'll be safe
        try? FileManager.default.removeItem(at: localURL)
    }

    private func handleFinalError(message: String) {
        statusMessage = "Error: Process Failed"
        triggerNotificationHaptic(.error)
        isDownloading = false
        alertTitle = "Download Failed"
        alertMessage = message
        showAlert = true
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
                self.downloadProgress = 1.0
                do {
                    try await self.finalizeDownload(localURL: destinationURL)
                    self.sendCompletionNotification() // Show completion banner
                } catch {
                    self.handleFinalError(message: "Failed to save video: \(error.localizedDescription)")
                }
            }
        } catch {
            Task { @MainActor in
                self.handleFinalError(message: "Failed to process downloaded file.")
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
