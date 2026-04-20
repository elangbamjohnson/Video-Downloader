# Video Downloader for iOS

A professional, high-performance video downloader for iOS built with SwiftUI. This app allows users to seamlessly download high-quality videos from popular social media platforms including **Facebook and Instagram** directly to their Photo Library.

## 🚀 Features

- **Smart Magic Paste ✨**: Proactive clipboard monitoring that automatically detects video links from supported platforms and suggests a "one-tap" download experience upon opening the app.
- **Multi-Platform Support**: Optimized for Facebook Reels/Videos and Instagram Reels/Stories.
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
- **MVVM Architecture**: Clean separation of concerns with a organized folder structure (**Models, Views, ViewModels, Services, Resources**).
- **Swift Concurrency**: `async/await` for smooth, non-blocking network operations.
- **Background Downloads**: Leverages `URLSession` background configuration to ensure downloads continue even if the app is suspended.
- **External Engines**: 
  - `LoadifyEngine.xcframework`: Proprietary binary extraction engine.
  - **Cobalt API Nodes**: Leverages community instances for maximum uptime.

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

1. **Copy** a video link from Facebook or Instagram.
2. **Open** the Video Downloader app.
3. **Smart Suggestion**: A card will automatically appear if a valid link is detected in your clipboard. Tap **"Download Now"** for instant processing.
4. **Manual**: Or, paste the link into the URL field and select your desired quality.
5. **Download**: Tap **Download Video** and monitor progress in real-time.
6. **Enjoy**: Once complete, find your video in the **Photos** app!

## 🤝 Contribution

Contributions are welcome! If you find a platform link that isn't working, please open an issue or submit a PR with an updated API instance.

---
*Created by Johnson - April 2026*
