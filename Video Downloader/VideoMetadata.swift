//
//  VideoMetadata.swift
//  Video Downloader
//
//  Created by Johnson on 17/04/26.
//

import Foundation

// MARK: - API Response Models
struct APIResponse: Codable {
    // Facebook API fields
    let success: Bool?
    let data: [MediaData]?
    let directMediaUrl: String?
    
    // Instagram/All-In-One fields
    let error: Bool?
    let message: String?
    let downloadUrl: String?
    let links: [MediaData]?
}

struct MediaData: Codable {
    let url: String?
    let link: String?
    let quality: String?
}
