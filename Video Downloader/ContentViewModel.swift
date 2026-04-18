//
//  ContentViewModel.swift
//  Video Downloader
//

import SwiftUI
import Photos
import Combine
import LoadifyEngine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var url: String = ""
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var selectedQuality: String = "720"
    
    let qualities = ["360", "480", "720", "1080", "max"]
    
    private let client = LoadifyClient()
    
    // Updated fallback instances of Cobalt API (verified for 2026)
    private let fallbackHosts = [
        "cobalt.canine.tools",
        "api-dl.cgm.rs",
        "cobalt.meowing.de",
        "cobalt.synzr.space"
    ]

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
        
        let localURL = try await downloadFile(from: videoURL)
        try await finalizeDownload(localURL: localURL)
    }

    private func tryFallbackAPI() async {
        for host in fallbackHosts {
            do {
                statusMessage = "Connecting to \(host)..."
                let downloadLink = try await fetchFromCobalt(host: host)
                statusMessage = "Downloading file..."
                let localURL = try await downloadFile(from: URL(string: downloadLink)!)
                try await finalizeDownload(localURL: localURL)
                return // Success!
            } catch {
                print("DEBUG: Fallback to \(host) failed: \(error)")
                continue
            }
        }
        
        // If all fallbacks fail
        handleFinalError(message: "All download services are currently unavailable. The video platform may have updated its security. Please try again later or with a different link.")
    }

    private func fetchFromCobalt(host: String) async throws -> String {
        guard let apiUrl = URL(string: "https://\(host)") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.timeoutInterval = 15 // Shorter timeout for faster fallback
        
        // Mandatory Headers for Cobalt API
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "url": url,
            "videoQuality": selectedQuality,
            "filenameStyle": "pretty"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        if httpResponse.statusCode != 200 {
            print("DEBUG: \(host) returned status \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(FallbackAPIResponse.self, from: data)
        
        if let downloadUrl = apiResponse.url { return downloadUrl }
        if let status = apiResponse.status, status == "error" {
            throw NSError(domain: "Cobalt", code: 400, userInfo: [NSLocalizedDescriptionKey: apiResponse.text ?? "Unknown API Error"])
        }
        
        throw URLError(.fileDoesNotExist)
    }

    private func downloadFile(from url: URL) async throws -> URL {
        let (localURL, response) = try await URLSession.shared.download(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        try FileManager.default.moveItem(at: localURL, to: destinationURL)
        return destinationURL
    }

    private func finalizeDownload(localURL: URL) async throws {
        statusMessage = "Saving to Gallery..."
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
        }
        statusMessage = "Successfully saved!"
        triggerNotificationHaptic(.success)
        isDownloading = false
        url = ""
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

// Separate model for Fallback API to avoid confusion with internal models
struct FallbackAPIResponse: Codable {
    let status: String?
    let url: String?
    let text: String?
}
