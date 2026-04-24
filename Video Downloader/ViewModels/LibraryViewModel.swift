//
//  LibraryViewModel.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 24/04/26.
//

import SwiftUI
import Photos

@MainActor
@Observable
class LibraryViewModel: NSObject, PHPhotoLibraryChangeObserver {
    var assets: PHFetchResult<PHAsset>?
    
    private let photoLibrary: PhotoLibraryProvider
    private let imageManager: PHImageCaching
    
    // Inject dependencies with defaults for production
    init(photoLibrary: PhotoLibraryProvider = PHPhotoLibrary.shared(),
         imageManager: PHImageCaching = PHCachingImageManager.default() as! PHImageCaching) {
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        super.init()
        self.photoLibrary.register(self)
        fetchAssets()
    }
    
    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }
    
    func fetchAssets() {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.assets = PHAsset.fetchAssets(with: options)
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            fetchAssets()
        }
    }
    
    func requestThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        _ = imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
}
