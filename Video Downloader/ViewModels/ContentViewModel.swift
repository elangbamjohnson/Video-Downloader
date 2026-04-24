//
//  ContentViewModel.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 17/04/26.
//


import SwiftUI
import Photos
import Combine
import UserNotifications

@MainActor
@Observable
class ContentViewModel: NSObject {
    var url: String = ""
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
    var statusMessage: String = ""
    var showAlert: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
    var selectedQuality: String = Constants.UI.defaultQuality
    
    var isUrlValid: Bool {
        isValidUrl(url)
    }
    
    // Smart Suggestion State
    var detectedURL: String? = nil
    var detectedPlatform: String = ""
    var showSuggestion: Bool = false
    
    private var processedUrls: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: Constants.Config.processedUrlsKey) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Constants.Config.processedUrlsKey)
        }
    }
    
    let qualities = Constants.UI.qualities
    
    private let downloadService: DownloadServiceProtocol

    @MainActor
    init(downloadService: DownloadServiceProtocol) {
        self.downloadService = downloadService
        super.init()
        self.downloadService.delegate = self
        setupNotifications()
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
        content.title = String(localized: Constants.Messages.notificationTitle)
        content.body = String(localized: Constants.Messages.notificationBody)
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
        print("DEBUG: startProcess called with URL: \(url)")
        guard !url.isEmpty else { 
            print("DEBUG: URL is empty, returning")
            return 
        }
        
        triggerHaptic(.light)
        isDownloading = true
        print("DEBUG: isDownloading set to true")
        
        Task {
            await downloadService.startDownload(url: url, quality: selectedQuality)
        }
    }

    func finalizeDownload(localURL: URL) async throws {
        statusMessage = String(localized: Constants.Messages.savingToGallery)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
        }
        statusMessage = String(localized: Constants.Messages.successfullySaved)
        triggerNotificationHaptic(.success)
        processedUrls.insert(url)
        isDownloading = false
        url = ""
        try? FileManager.default.removeItem(at: localURL)
    }

    private func handleFinalError(message: String) {
        statusMessage = String(localized: Constants.Messages.processFailed)
        triggerNotificationHaptic(.error)
        isDownloading = false
        alertTitle = String(localized: Constants.Messages.downloadFailed)
        alertMessage = message
        showAlert = true
    }

    // MARK: - Smart Magic Paste Logic
    
    func checkClipboard(explicitString: String? = nil) {
        let stringToCheck = explicitString ?? UIPasteboard.general.string
        print("DEBUG: Checking string: \(String(describing: stringToCheck))")
        
        guard let clipboardString = stringToCheck?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardString.isEmpty else { 
            print("DEBUG: Clipboard string is empty")
            return 
        }
        
        guard clipboardString != self.url else { 
            print("DEBUG: URL is same as current")
            return 
        }
        
        guard !processedUrls.contains(clipboardString) else {
            print("DEBUG: URL already processed")
            return
        }
        
        let lowercased = clipboardString.lowercased()
        var platform = ""
        
        if lowercased.contains("instagram.com") {
            platform = Constants.UI.instagramName
        } else if lowercased.contains("facebook.com") || lowercased.contains("fb.watch") {
            platform = Constants.UI.facebookName
        }
        
        print("DEBUG: Detected platform: \(platform)")
        
        if !platform.isEmpty {
            self.detectedURL = clipboardString
            self.detectedPlatform = String(format: String(localized: Constants.UI.linkDetectedTitle), platform)
            self.showSuggestion = true
            print("DEBUG: showSuggestion set to true")
        }
    }
    
    func useDetectedURL() {
        guard let urlToUse = detectedURL else { return }
        
        withAnimation(.spring()) {
            self.url = urlToUse
            self.showSuggestion = false
            self.detectedURL = nil
        }
        
        triggerHaptic(.medium)
        startProcess()
    }
    
    func dismissSuggestion() {
        withAnimation(.spring()) {
            self.showSuggestion = false
            self.detectedURL = nil
        }
    }

    private func isValidUrl(_ urlString: String) -> Bool {
        let cleanUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUrl.isEmpty else { return false }
        
        let instagramRange = cleanUrl.range(of: Constants.Config.instagramRegex, options: .regularExpression)
        let facebookRange = cleanUrl.range(of: Constants.Config.facebookRegex, options: .regularExpression)
        
        return instagramRange != nil || facebookRange != nil
    }
}

// MARK: - DownloadServiceDelegate
extension ContentViewModel: DownloadServiceDelegate {
    nonisolated func downloadService(_ service: DownloadServiceProtocol, didUpdateProgress progress: Double) {
        Task { @MainActor in
            self.downloadProgress = progress
        }
    }
    
    nonisolated func downloadService(_ service: DownloadServiceProtocol, didFinishWithLocation location: URL) {
        Task { @MainActor in
            do {
                try await self.finalizeDownload(localURL: location)
                self.sendCompletionNotification()
            } catch {
                let errorFormat = String(localized: Constants.Messages.failedToSaveVideo)
                let localizedError = String(format: errorFormat, error.localizedDescription)
                self.handleFinalError(message: localizedError)
            }
        }
    }
    
    nonisolated func downloadService(_ service: DownloadServiceProtocol, didFailWithError error: Error) {
        Task { @MainActor in
            self.handleFinalError(message: error.localizedDescription)
        }
    }
    
    nonisolated func downloadService(_ service: DownloadServiceProtocol, didUpdateStatus status: String) {
        Task { @MainActor in
            self.statusMessage = status
        }
    }
}
