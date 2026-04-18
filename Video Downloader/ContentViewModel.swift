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
    
    // Most reliable and active Cobalt instances for 2026
    private let fallbackHosts = [
        "https://cobalt.canine.tools",
        "https://cobalt.meowing.de",
        "https://cobalt.sh",
        "https://cobalt.inst.moe"
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
            // Systematic attempt: try root first (modern Cobalt), then /api/json (classic)
            let paths = ["/", "/api/json"]
            
            for path in paths {
                let endpoint = host + path
                do {
                    let displayHost = host.replacingOccurrences(of: "https://", with: "")
                    statusMessage = "Connecting to \(displayHost)..."
                    
                    let downloadLink = try await fetchFromCobalt(endpoint: endpoint)
                    
                    statusMessage = "Downloading file..."
                    guard let dlURL = URL(string: downloadLink) else { continue }
                    let localURL = try await downloadFile(from: dlURL)
                    
                    try await finalizeDownload(localURL: localURL)
                    return // Success!
                } catch {
                    print("DEBUG: Fallback to \(endpoint) failed: \(error)")
                    // If we get a 400 or 404, it might be the wrong path for this host, so continue to next path/host
                    continue
                }
            }
        }
        
        // If all fallbacks fail
        handleFinalError(message: "All download services are currently unavailable for this link. The platform may have updated its security. Please try another link or try again later.")
    }

    private func fetchFromCobalt(endpoint: String) async throws -> String {
        guard let apiUrl = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.timeoutInterval = 8 // Faster cycling
        
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
            throw NSError(domain: "Cobalt", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned \(httpResponse.statusCode)"])
        }
        
        let apiResponse = try JSONDecoder().decode(FallbackAPIResponse.self, from: data)
        
        if let downloadUrl = apiResponse.url, !downloadUrl.isEmpty { return downloadUrl }
        
        if let status = apiResponse.status, status == "error" {
            throw NSError(domain: "Cobalt", code: 400, userInfo: [NSLocalizedDescriptionKey: apiResponse.text ?? "Unknown API Error"])
        }
        
        throw URLError(.fileDoesNotExist)
    }

    private func downloadFile(from url: URL) async throws -> URL {
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let totalBytes = httpResponse.expectedContentLength
        var downloadedData = Data()
        
        if totalBytes > 0 {
            downloadedData.reserveCapacity(Int(totalBytes))
        }
        
        for try await byte in bytes {
            downloadedData.append(byte)
            
            if totalBytes > 0 {
                let progress = Double(downloadedData.count) / Double(totalBytes)
                // Update progress on the main actor
                if Int(progress * 100) % 5 == 0 { // Update every 5% to reduce UI jitter
                    self.downloadProgress = progress
                }
            }
        }
        
        self.downloadProgress = 1.0
        
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        try downloadedData.write(to: destinationURL)
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

struct FallbackAPIResponse: Codable {
    let status: String?
    let url: String?
    let text: String?
}
