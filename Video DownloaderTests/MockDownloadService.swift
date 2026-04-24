

//
//  MockDownloadService.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 21/04/26.
//

import Foundation
@testable import Video_Downloader

@MainActor
class MockDownloadService: DownloadServiceProtocol {
    weak var delegate: DownloadServiceDelegate?
    
    // Tracking properties to verify if methods were called
    var startDownloadCalled = false
    var lastURL: String?
    
    // Control properties to simulate different outcomes
    var shouldSucceed = true
    
    func startDownload(url: String, quality: String) async {
        startDownloadCalled = true
        lastURL = url
        
        // Simulate immediate status update
        delegate?.downloadService(self, didUpdateStatus: "Mock Analyzing...")
        
        if shouldSucceed {
            // Simulate progress
            delegate?.downloadService(self, didUpdateProgress: 0.5)
        } else {
            let error = NSError(domain: "MockError", code: -1, userInfo:
                                    [NSLocalizedDescriptionKey: "Mock Failure"])
            delegate?.downloadService(self, didFailWithError: error)
        }
    }
}
