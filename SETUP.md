# ECHO macOS App - Setup Instructions

## Required Permissions

The ECHO macOS App now includes screen capture and OCR capabilities. To use these features, you need to add the following privacy descriptions to your app's Info.plist:

### Adding Privacy Descriptions in Xcode

1. Open `ECHO-macOS-App.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "ECHO-macOS-App" target
4. Go to the "Info" tab
5. Add the following keys:

#### NSAccessibilityUsageDescription
**Value:** "ECHO needs accessibility access to track window positions and application activity for productivity monitoring."

#### NSScreenCaptureUsageDescription  
**Value:** "ECHO needs screen recording permission to capture screenshots for OCR text analysis and activity tracking."

### Alternative: Edit Info.plist Directly

If you prefer to edit the Info.plist file directly, add these entries:

```xml
<key>NSAccessibilityUsageDescription</key>
<string>ECHO needs accessibility access to track window positions and application activity for productivity monitoring.</string>
<key>NSScreenCaptureUsageDescription</key>
<string>ECHO needs screen recording permission to capture screenshots for OCR text analysis and activity tracking.</string>
```

## Granting Permissions

After adding these descriptions and running the app:

1. Navigate to **System Settings → Privacy & Security → Accessibility**
2. Enable "ECHO-macOS-App" in the list
3. Navigate to **System Settings → Privacy & Security → Screen Recording**
4. Enable "ECHO-macOS-App" in the list

## Using Screen Capture

1. Launch the app
2. Click on "Screen Capture" in the sidebar
3. Click "Capture & Scan" to take a screenshot and analyze it
4. View detected windows and their text in the right panel
5. Click on windows to highlight their text on the screenshot

## Features

- **OCR Text Recognition**: Automatically extracts text from screenshots using Apple Vision
- **Window Mapping**: Maps detected text to specific application windows
- **Visual Overlays**: Shows green boxes for all detected text, yellow for selected window
- **Event Tracking**: Can log OCR detections as events for activity tracking