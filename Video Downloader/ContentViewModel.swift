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
    private let rapidAPIHost = "auto-download-all-in-one.p.rapidapi.com"

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
        // Using the Unified API (FastSaverAPI) for both FB and IG
        guard var components = URLComponents(string: "https://\(rapidAPIHost)/v1/get-info") else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [URLQueryItem(name: "url", value: videoURL)]
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Headers
        request.addValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue(rapidAPIHost, forHTTPHeaderField: "X-RapidAPI-Host")
        
        print("DEBUG: Fetching info for \(videoURL) using GET from Unified API")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("DEBUG: Raw JSON Response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "VideoDownloader", code: code, userInfo: [NSLocalizedDescriptionKey: "Server returned error \(code)"])
        }
        
        let apiResponse = try JSONDecoder.codableValue.decode(APIResponse.self, from: data)
        
        if apiResponse.error == true {
            throw NSError(domain: "VideoDownloader", code: 400, userInfo: [NSLocalizedDescriptionKey: apiResponse.message ?? "API Error"])
        }
        
        // 1. Try primary downloadUrl field
        if let direct = apiResponse.downloadUrl, !direct.isEmpty {
            return direct
        }
        
        // 2. Try secondary directMediaUrl field
        if let direct = apiResponse.directMediaUrl, !direct.isEmpty {
            return direct
        }
        
        // 3. Try links array
        if let links = apiResponse.links, let first = links.first, let link = first.link ?? first.url {
            return link
        }
        
        throw NSError(domain: "VideoDownloader", code: 404, userInfo: [NSLocalizedDescriptionKey: "No download link found. Please verify the link is public and accessible."])
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

// Helper extension for logic-related decoding
extension JSONDecoder {
    static var codableValue: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
