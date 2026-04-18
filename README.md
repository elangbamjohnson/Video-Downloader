# Video Downloader for iOS

A professional, high-performance video downloader for iOS built with SwiftUI. This app allows users to seamlessly download high-quality videos from popular social media platforms including **Facebook, Instagram, TikTok, and X (Twitter)** directly to their Photo Library.

## 🚀 Features

- **Multi-Platform Support**: Optimized for Facebook Reels/Videos, Instagram Reels/Stories, TikTok, and X.
- **Smart Processing Engine**: 
  - **Primary**: Powered by `LoadifyEngine.xcframework` for high-speed, direct extraction.
  - **Fallback**: Intelligent multi-service fallback system that automatically cycles through multiple global **Cobalt API** nodes if the primary engine encounters platform-specific updates or decoding issues.
- **Quality Control**: Select your preferred resolution (360p, 480p, 720p, 1080p, or Max Quality).
- **Premium UI/UX**:
  - Vibrant "Liquid Glass" design with custom gradients.
  - Real-time download progress tracking.
  - Native Haptic Feedback (`UIImpactFeedbackGenerator`) for every action.
- **Auto-Save**: Automatic validation and saving to the iOS Photo Library with proper permissions handling.

## 🛠 Tech Stack

- **SwiftUI**: Modern declarative UI.
- **MVVM Architecture**: Clean separation of concerns between view and logic.
- **Swift Concurrency**: `async/await` for smooth, non-blocking network operations.
- **External Engines**: 
  - `LoadifyEngine.xcframework`: Proprietary binary extraction engine.
  - **Cobalt API Nodes**: Leverages community instances (`cobalt.canine.tools`, `api-dl.cgm.rs`, etc.) for maximum uptime.

## 📦 Installation & Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/elangbamjohnson/Video-Downloader.git
   ```

2. **Framework Integration**:
   Ensure `LoadifyEngine.xcframework` is present in the project root.
   In Xcode:
   - Go to **Target** > **General** > **Frameworks, Libraries, and Embedded Content**.
   - Ensure `LoadifyEngine.xcframework` is set to **Embed & Sign**.

3. **Permissions**:
   The app requires `NSPhotoLibraryAddUsageDescription` in `Info.plist` to save videos to the gallery.

## 📖 How to Use

1. Copy a video link from your favorite app (Facebook, Instagram, etc.).
2. Paste the link into the URL field.
3. Select your desired quality.
4. Tap **Download Video**.
5. Once complete, find your video in the **Photos** app!

## 🤝 Contribution

Contributions are welcome! If you find a platform link that isn't working, please open an issue or submit a PR with an updated API instance.

---
*Created by Johnson - April 2026*
