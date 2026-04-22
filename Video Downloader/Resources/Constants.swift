//
//  Constants.swift
//  Video Downloader
//
//  Created by Johnson on 17/04/26.
//

import Foundation
import SwiftUI

struct Constants {
    
    struct Config {
        static let backgroundSessionIdentifier = "com.video.downloader.background"
        static let httpMaximumConnectionsPerHost = 6
        static let requestTimeout: TimeInterval = 10
        static let maxDownloadProgress: Double = 1.0
        static let defaultStatusCode = 200
        static let errorCode = 400
        static let errorDomain = "Cobalt"
        
        // Persistence
        static let processedUrlsKey = "processed_urls"
        
        // Validation Regex
        static let instagramRegex = #"(https?://)?(www\.)?instagram\.com/.*"#
        static let facebookRegex = #"(https?://)?(www\.)?(facebook\.com|fb\.watch)/.*"#
    }
    
    struct API {
        static let cobaltHosts = [
            "https://cobalt.canine.tools",
            "https://cobalt.meowing.de",
            "https://cobalt.sh",
            "https://cobalt.inst.moe"
        ]
        
        static let apiEndpoints = ["/", "/api/json"]
        static let httpMethodPost = "POST"
        static let contentTypeHeader = "Content-Type"
        static let acceptHeader = "Accept"
        static let applicationJson = "application/json"
        
        static let bodyKeyUrl = "url"
        static let bodyKeyVideoQuality = "videoQuality"
        static let bodyKeyDownloadMode = "downloadMode"
        static let bodyKeyVCodec = "vCodec"
        static let bodyKeyAFormat = "aFormat"
        static let bodyKeyFilenameStyle = "filenameStyle"
        
        static let downloadModeTunnel = "tunnel"
        static let vCodecH264 = "h264"
        static let aFormatMp3 = "mp3"
        static let filenameStylePretty = "pretty"
        
        static let statusError = "error"
    }
    
    struct UI {
        static let appTitle: LocalizedStringResource = "Video Downloader"
        static let appSubtitle: LocalizedStringResource = "Fast, High Quality, No Ads"
        static let urlPlaceholder: LocalizedStringResource = "Paste link from Instagram or Facebook"
        static let enterUrlTitle: LocalizedStringResource = "Enter Video URL"
        static let qualityPreferenceTitle: LocalizedStringResource = "Quality Preference"
        static let downloadButtonTitle: LocalizedStringResource = "Download Video"
        static let supportedPlatformsTitle: LocalizedStringResource = "Supported Platforms"
        static let okButtonTitle: LocalizedStringResource = "OK"
        static let downloadNowTitle: LocalizedStringResource = "Download Now"
        static let dismissTitle: LocalizedStringResource = "Dismiss"
        static let linkDetectedTitle: LocalizedStringResource = "✨ Link Detected from %@"
        static let suggestionDescription: LocalizedStringResource = "Would you like to download this video?"
        
        static let instagramName = "Instagram"
        static let instagramIcon = "camera.fill"
        static let facebookName = "Facebook"
        static let facebookIcon = "f.circle.fill"
        static let mainAppIcon = "icloud.and.arrow.down"
        
        static let qualities = ["360", "480", "720", "1080", "max"]
        static let defaultQuality = "360"
        
        static let cornerRadiusLarge: CGFloat = 14
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusSmall: CGFloat = 10
        
        static let shadowRadius: CGFloat = 5
        static let shadowY: CGFloat = 2
        static let shadowOpacity: Double = 0.05
        
        static let statusMessageErrorPrefix = "Error"
        static let progressPercentFormat = "%d%%"
    }
    
    struct Messages {
        static let notificationTitle: LocalizedStringResource = "Download Complete"
        static let notificationBody: LocalizedStringResource = "Your video has been successfully saved to the Gallery."
        static let analyzingLink: LocalizedStringResource = "Analyzing link..."
        static let engineIssueFallback: LocalizedStringResource = "Engine issue. Trying fallback..."
        static let downloadingFrom: LocalizedStringResource = "Downloading from %@..."
        static let connectingTo: LocalizedStringResource = "Connecting to %@..."
        static let downloadingFile: LocalizedStringResource = "Downloading file..."
        static let allServicesUnavailable: LocalizedStringResource = "All download services are currently unavailable. Please try again later."
        static let savingToGallery: LocalizedStringResource = "Saving to Gallery..."
        static let successfullySaved: LocalizedStringResource = "Successfully saved!"
        static let processFailed: LocalizedStringResource = "Error: Process Failed"
        static let downloadFailed: LocalizedStringResource = "Download Failed"
        static let failedToSaveVideo: LocalizedStringResource = "Failed to save video: %@"
        static let failedToProcessFile: LocalizedStringResource = "Failed to process downloaded file."
    }
}
