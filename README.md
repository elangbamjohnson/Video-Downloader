# Video Downloader for iOS 📱

[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0+-blue.svg?style=flat)](https://apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A professional-grade, high-performance video downloader for iOS built with **SwiftUI**. This application provides a seamless experience for extracting and saving high-quality media from social platforms like Facebook and Instagram directly to the native iOS Photo Library.

## ✨ Key Features

- **Smart Magic Paste**: Utilizes proactive clipboard monitoring to detect video links automatically, offering a "one-tap" download experience immediately upon app launch.
- **Dual-Engine Extraction**: 
    - **Primary**: High-speed extraction via `LoadifyEngine.xcframework`.
    - **Fallback**: Intelligent multi-service fallback system leveraging global **Cobalt API** nodes to ensure high availability.
- **Advanced Quality Selection**: Supports multiple resolutions (360p to 1080p/Max Quality) with real-time metadata parsing.
- **Premium UX/UI**: Features a "Liquid Glass" design aesthetic, custom gradients, and integrated **Haptic Feedback** (`UIImpactFeedbackGenerator`) for a tactile user experience.
- **Robust Background Processing**: Leverages `URLSession` background configurations to ensure downloads complete even when the app is minimized.
- **Photo Library Integration**: Automated permission handling and validation for saving content directly to `PHAsset` collections.

## 🛠 Tech Stack

- **UI Framework**: SwiftUI (Declarative UI)
- **Architecture**: MVVM (Model-View-ViewModel) for clean separation of concerns and testability.
- **Concurrency**: Modern Swift `async/await` for non-blocking network and extraction logic.
- **Networking**: `URLSession` with background transfer support.
- **Dependency Management**: Local XCFramework integration for proprietary logic.
- **Feedback**: CoreHaptics / UIKit Haptics integration.

## 📦 Project Structure

```text
Video Downloader/
├── Models/             # Data structures and Video Metadata
├── Views/              # SwiftUI Components and Liquid Glass UI
├── ViewModels/         # Business logic and state management
├── Services/           # Download & Extraction service layers
└── Resources/          # Constants, Localizable strings, and Assets
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ Target Device/Simulator
- `LoadifyEngine.xcframework` (Included in root)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/elangbamjohnson/Video-Downloader.git
   ```
2. Open `Video Downloader.xcodeproj` in Xcode.
3. Ensure `LoadifyEngine.xcframework` is set to **"Embed & Sign"** in the Target settings under *General > Frameworks, Libraries, and Embedded Content*.
4. Build and Run on a physical device for the best experience (Haptics and Photo Library).

## 🛡 Permissions
The app requires the following key in your `Info.plist`:
- `NSPhotoLibraryAddUsageDescription`: Required to save downloaded videos to your gallery.

## 🤝 Contributing
Contributions are what make the open-source community an amazing place to learn, inspire, and create.
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Developed with ❤️ by **Johnson Elangbam** (April 2026)*
