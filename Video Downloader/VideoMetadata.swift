//
//  VideoMetadata.swift
//  Video Downloader
//
//  Created by Johnson on 17/04/26.
//

import Foundation

// MARK: - API Response Models (Unified for FastSaverAPI)
struct APIResponse: Codable {
    let error: Bool?
    let message: String?
    let title: String?
    let thumbnail: String?
    let duration: String?
    let hosting: String?
    
    // Direct URL field often used by this API
    let downloadUrl: String?
    
    // Alternative field: array of links
    let links: [MediaData]?
    
    // Legacy support field from previous attempts
    let directMediaUrl: String?
}

struct MediaData: Codable {
    let url: String?
    let link: String?
    let quality: String?
}
