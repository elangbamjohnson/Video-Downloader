//
//  Video_DownloaderApp.swift
//  Video Downloader
//
//  Created by Johnson on 17/04/26.
//

import SwiftUI

@main
struct Video_DownloaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel(downloadService: DownloadService()))
        }
        .backgroundTask(.urlSession(Constants.Config.backgroundSessionIdentifier)) {
            // This allows the app to handle background events even if it was terminated
            print("DEBUG: Handling background URL session events")
        }
    }
}
