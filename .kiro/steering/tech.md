# Tech Stack

## Language & Frameworks
- Swift 5.10+
- SwiftUI (macOS native UI)
- SwiftData (persistence, SQLite-backed)
- Apple MLX / mlx-swift (on-device LLM inference)
- AVFoundation (text-to-speech via AVSpeechSynthesizer)
- AppKit (NSSound for audio feedback)

## Dependencies (Swift Package Manager)
- `mlx-swift` 0.29.x — MLX tensor framework
- `mlx-swift-lm` 2.29.x — LLM loading and generation
- `swift-transformers` 1.1.x — HuggingFace tokenizers
- `swift-jinja` 2.2.x — Jinja template support for chat templates
- `swift-collections` 1.3.x
- `swift-numerics` 1.1.x

## Build System
- Xcode project (`LearningKit.xcodeproj`) — not a Swift Package
- SPM for dependency resolution (integrated via Xcode)
- No CocoaPods or Carthage

## Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15+
- Apple Silicon (M1/M2/M3) — required for MLX GPU/NPU acceleration

## Build & Run
```bash
# Open in Xcode
open LearningKit.xcodeproj

# Build and run via Xcode: Cmd+R
# No CLI build scripts are configured
```

## Data Storage
- SwiftData store at: `~/Library/Application Support/LearningKit/LearningKit.store`
- App logs at: `~/Library/Application Support/LearningKit/LearningKit.log`
- LLM model path stored in UserDefaults (`modelPath` key), selected by user at runtime
