//
//  MediaLibraryView.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 24/04/26.
//

import SwiftUI
import Photos
import AVKit

@MainActor
struct MediaLibraryView: View {
    var viewModel: LibraryViewModel
    
    init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let assets = viewModel.assets, assets.count > 0 {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(0..<assets.count, id: \.self) { index in
                            ThumbnailView(asset: assets[index], viewModel: viewModel)
                        }
                    }
                } else {
                    ContentUnavailableView("No Videos", systemImage: "video.slash", description: Text("Your downloaded videos will appear here."))
                }
            }
            .navigationTitle("Library")
        }
    }
}

struct ThumbnailView: View {
    let asset: PHAsset
    let viewModel: LibraryViewModel
    @State private var image: UIImage?
    
    var body: some View {
        NavigationLink(destination: VideoPlayerView(asset: asset)) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(1, contentMode: .fill)
                }
                
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.title2)
            }
            .clipped()
            .onAppear {
                viewModel.requestThumbnail(for: asset, size: CGSize(width: 200, height: 200)) { image in
                    self.image = image
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    let asset: PHAsset
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                PHCachingImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
                    if let avAsset = avAsset {
                        let playerItem = AVPlayerItem(asset: avAsset)
                        DispatchQueue.main.async {
                            self.player = AVPlayer(playerItem: playerItem)
                            self.player?.play()
                        }
                    }
                }
            }
            .onDisappear {
                player?.pause()
            }
    }
}
