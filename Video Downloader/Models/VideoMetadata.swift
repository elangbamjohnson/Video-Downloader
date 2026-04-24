//
//  VideoMetadata.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 17/04/26.
//

import Foundation

// MARK: - API Response Models (Cobalt API)
struct APIResponse: Codable {
    let status: String? // "success", "error", "redirect", "picker"
    let url: String?    // The direct download URL
    let text: String?   // Error message if status is "error"
}
