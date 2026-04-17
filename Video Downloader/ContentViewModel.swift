//
//  ContentViewModel.swift
//  Video Downloader
//
//  Created by Johnson on 17/04/26.
//

import SwiftUI
import Photos
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var url: String = ""
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    private let rapidAPIKey = "527c409d18mshf17577cf03a5410p17d717jsn26603340f1ba"

    func startProcess() {
        guard !url.isEmpty else { return }
        
        isDownloading = true
        statusMessage = "Analyzing link..."
        downloadProgress = 0.0
        
        Task {
            do {
                let downloadLink = try await fetchVideoInfo(for: url)
                statusMessage = "Downloading file..."
                let localURL = try await downloadFile(from: downloadLink)
                statusMessage = "Saving to Gallery..."
                try await saveToPhotos(fileURL: localURL)
                statusMessage = "Successfully saved!"
                isDownloading = false
                url = ""
            } catch {
                print("DEBUG: Final catch error: \(error)")
                statusMessage = "Error: \(error.localizedDescription)"
                isDownloading = false
                alertTitle = "Process Failed"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func fetchVideoInfo(for videoURL: String) async throws -> String {
        let isFacebook = videoURL.contains("facebook.com") || videoURL.contains("fb.watch")
        
        let host = isFacebook ? "facebook-media-downloader1.p.rapidapi.com" : "auto-download-all-in-one.p.rapidapi.com"
        let path = isFacebook ? "/get_media" : "/v1/get-info"
        let method = isFacebook ? "POST" : "GET"
        
        var request: URLRequest
        
        if method == "POST" {
            request = URLRequest(url: URL(string: "https://\(host)\(path)")!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["url": videoURL]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        } else {
            var components = URLComponents(string: "https://\(host)\(path)")!
            components.queryItems = [URLQueryItem(name: "url", value: videoURL)]
            request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
        }
        
        request.timeoutInterval = 20
        request.addValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue(host, forHTTPHeaderField: "x-rapidapi-host")
        
        print("DEBUG: Fetching from \(host) using \(method)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("DEBUG: Raw JSON Response: \(jsonString)")
        }
        
        let apiResponse = try JSONDecoder.codableValue.decode(APIResponse.self, from: data)
        
        // 1. Check direct_media_url (Latest Facebook format)
        if let direct = apiResponse.directMediaUrl, !direct.isEmpty {
            return direct
        }
        
        // 2. Try data array
        if let mediaData = apiResponse.data, let first = mediaData.first {
            if let link = first.url ?? first.link { return link }
        }
        
        // 3. Try direct downloadUrl
        if let direct = apiResponse.downloadUrl, !direct.isEmpty {
            return direct
        }
        
        // 4. Try links array
        if let links = apiResponse.links, let first = links.first, let link = first.link ?? first.url {
            return link
        }
        
        throw NSError(domain: "VideoDownloader", code: 404, userInfo: [NSLocalizedDescriptionKey: "No download link found in response."])
    }
    
    private func downloadFile(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (localURL, response) = try await URLSession.shared.download(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        try FileManager.default.moveItem(at: localURL, to: destinationURL)
        return destinationURL
    }
    
    private func saveToPhotos(fileURL: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
}

// Helper extension moved to ViewModel file as it's logic-related
extension JSONDecoder {
    static var codableValue: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
