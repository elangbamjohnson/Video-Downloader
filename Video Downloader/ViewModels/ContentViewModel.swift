//
//  ContentViewModel.swift
//  Video Downloader
//

import SwiftUI
import Photos
import Combine
import UserNotifications

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
    
    private let downloadService = DownloadService()

    override init() {
        super.init()
        downloadService.delegate = self
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
        
        Task {
            await downloadService.startDownload(url: url, quality: selectedQuality)
        }
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

// MARK: - DownloadServiceDelegate
extension ContentViewModel: DownloadServiceDelegate {
    nonisolated func downloadService(_ service: DownloadService, didUpdateProgress progress: Double) {
        Task { @MainActor in
            self.downloadProgress = progress
        }
    }
    
    nonisolated func downloadService(_ service: DownloadService, didFinishWithLocation location: URL) {
        Task { @MainActor in
            do {
                try await self.finalizeDownload(localURL: location)
                self.sendCompletionNotification()
            } catch {
                self.handleFinalError(message: String(format: Constants.Messages.failedToSaveVideo, error.localizedDescription))
            }
        }
    }
    
    nonisolated func downloadService(_ service: DownloadService, didFailWithError error: Error) {
        Task { @MainActor in
            self.handleFinalError(message: error.localizedDescription)
        }
    }
    
    nonisolated func downloadService(_ service: DownloadService, didUpdateStatus status: String) {
        Task { @MainActor in
            self.statusMessage = status
        }
    }
}
