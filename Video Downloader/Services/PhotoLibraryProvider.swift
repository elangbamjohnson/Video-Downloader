//
//  PhotoLibraryProvider.swift
//  Video Downloader
//
//  Created by Johnson Elangbam on 24/04/26.
//

import Foundation
import Photos
import UIKit

protocol PhotoLibraryProvider: AnyObject {
    func register(_ observer: PHPhotoLibraryChangeObserver)
    func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver)
}

extension PHPhotoLibrary: PhotoLibraryProvider {}

protocol PHImageCaching: AnyObject {
    func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID
}

extension PHCachingImageManager: PHImageCaching {}
