//
//  Video_DownloaderApp.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 17/04/26.
//

import SwiftUI

@main
struct Video_DownloaderApp: App {
    @State private var contentViewModel = ContentViewModel(downloadService: DownloadService())
    @State private var libraryViewModel = LibraryViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: contentViewModel)
                    .tabItem {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                    }
                
                MediaLibraryView(viewModel: libraryViewModel)
                    .tabItem {
                        Label("Library", systemImage: "photo.stack.fill")
                    }
            }
        }
        .backgroundTask(.urlSession(Constants.Config.backgroundSessionIdentifier)) {
            // This allows the app to handle background events even if it was terminated
            print("DEBUG: Handling background URL session events")
        }
    }
}
