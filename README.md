# Project-Echo

ECHO is a macOS productivity tracking application built with SwiftUI that monitors your activity, tracks time spent across projects, and provides intelligent insights through OCR and window analysis.

## Features

- **Activity Dashboard**: Real-time view of your daily productivity stats
- **Timeline View**: Detailed timeline of your work sessions
- **Screen Capture & OCR**: Capture screenshots and extract text using Apple Vision
- **Window Tracking**: Automatically map detected text to application windows
- **Project Management**: Track time across multiple projects
- **Event Logging**: Comprehensive activity tracking with SwiftData

## Getting Started

1. Open `ECHO-macOS-App.xcodeproj` in Xcode
2. Follow the setup instructions in [SETUP.md](SETUP.md) to configure permissions
3. Build and run the app (⌘R)

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Project Structure

```
ECHO-macOS-App/
├── Models/           # Data models (Event, OCRModels)
├── Services/         # Business logic (ActivityManager, OCREngine, WindowManager)
├── Views/            # SwiftUI views
└── Assets.xcassets/  # App assets and images
```

## Privacy & Permissions

This app requires:
- **Accessibility** permission for window tracking
- **Screen Recording** permission for screenshot capture

See [SETUP.md](SETUP.md) for detailed setup instructions.

## License

MIT License