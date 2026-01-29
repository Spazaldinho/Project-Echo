import SwiftUI
import UniformTypeIdentifiers

struct ScreenCaptureView: View {
    @Bindable var activityManager: ActivityManager
    @State private var selectedWindowID: UUID?
    @State private var isProcessing = false
    
    var body: some View {
        HSplitView {
            // --- Left Panel: Image & Overlays ---
            VStack {
                Text("Screen Capture")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                
                ZStack {
                    if let image = activityManager.capturedImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .overlay(
                                GeometryReader { geo in
                                    // Calculate image scaling to draw boxes correctly
                                    let scale = min(geo.size.width / image.size.width, geo.size.height / image.size.height)
                                    let offsetX = (geo.size.width - image.size.width * scale) / 2
                                    let offsetY = (geo.size.height - image.size.height * scale) / 2
                                    
                                    // Get the text results for the selected window to highlight them
                                    let selectedWindowTextIds = activityManager.mappedWindows.first(where: { $0.id == selectedWindowID })?.containedText.map { $0.id } ?? []
                                    
                                    ForEach(activityManager.ocrResults) { result in
                                        let isHighlighted = selectedWindowTextIds.contains(result.id)
                                        
                                        Rectangle()
                                            .stroke(isHighlighted ? Color.yellow : Color.green, lineWidth: isHighlighted ? 3 : 1)
                                            .background(isHighlighted ? Color.yellow.opacity(0.3) : Color.green.opacity(0.1))
                                            .frame(width: result.bounds.width * scale, height: result.bounds.height * scale)
                                            .position(
                                                x: (result.bounds.x + result.bounds.width / 2) * scale + offsetX,
                                                y: (result.bounds.y + result.bounds.height / 2) * scale + offsetY
                                            )
                                            .animation(.easeInOut, value: selectedWindowID)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.subtleBorder, lineWidth: 1)
                            )
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                    Text("No Screenshot Captured")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                    Text("Click 'Capture & Scan' to take a screenshot and analyze it")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.mutedGray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                
                HStack(spacing: 15) {
                    Button(action: { Task { await captureAndScan() } }) {
                        Label("Capture & Scan", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                    
                    Button(action: selectScreenshot) {
                        Label("Load File", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isProcessing)
                    
                    Button(action: { processMapping() }) {
                        Label("Refresh", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(activityManager.capturedImage == nil || isProcessing)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                if isProcessing {
                    ProgressView("Processing...")
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }
            .frame(minWidth: 500)
            .layoutPriority(1)
            
            // --- Right Panel: Mapped Results ---
            VStack(alignment: .leading, spacing: 20) {
                Text("Detected Windows")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                
                if activityManager.mappedWindows.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                        Text("No windows detected")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        Text("Capture a screenshot to see window mapping")
                            .font(.subheadline)
                            .foregroundStyle(Color.mutedGray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(activityManager.mappedWindows) { mapped in
                                WindowCard(
                                    mapped: mapped,
                                    isSelected: selectedWindowID == mapped.id,
                                    onTap: {
                                        withAnimation {
                                            selectedWindowID = selectedWindowID == mapped.id ? nil : mapped.id
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(minWidth: 350)
        }
        .background(Color.contentBackground)
    }
    
    // MARK: - Business Logic
    
    @MainActor private func captureAndScan() async {
        isProcessing = true
        selectedWindowID = nil
        await activityManager.performScreenCapture()
        isProcessing = false
    }
    
    private func selectScreenshot() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            if let url = panel.url, let image = NSImage(contentsOf: url) {
                activityManager.capturedImage = image
                activityManager.ocrResults = []
                activityManager.mappedWindows = []
                selectedWindowID = nil
                processMapping()
            }
        }
    }
    
    private func processMapping() {
        guard let image = activityManager.capturedImage else { return }
        isProcessing = true
        
        let ocrEngine = OCREngine()
        let windowManager = WindowManager()
        
        ocrEngine.performOCR(on: image) { results in
            activityManager.ocrResults = results
            let windows = windowManager.getVisibleWindows()
            
            // Map text to windows
            var windowMapping: [UUID: [OCRResult]] = [:]
            
            for textResult in results {
                let centerX = textResult.bounds.x + textResult.bounds.width / 2
                let centerY = textResult.bounds.y + textResult.bounds.height / 2
                let pointInPoints = CGPoint(x: centerX, y: centerY)
                
                if let topmostWindow = windows.first(where: { $0.frame.cgRect.contains(pointInPoints) }) {
                    windowMapping[topmostWindow.id, default: []].append(textResult)
                }
            }
            
            // Create mapped windows
            var tempMapped: [MappedWindow] = []
            for window in windows {
                let textInWindow = windowMapping[window.id] ?? []
                if !textInWindow.isEmpty {
                    tempMapped.append(MappedWindow(window: window, containedText: textInWindow))
                }
            }
            
            activityManager.mappedWindows = tempMapped.sorted { $0.containedText.count > $1.containedText.count }
            isProcessing = false
        }
    }
}

// MARK: - Window Card Component

struct WindowCard: View {
    let mapped: MappedWindow
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "macwindow")
                    .foregroundStyle(Color.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapped.window.ownerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    if !mapped.window.windowTitle.isEmpty {
                        Text(mapped.window.windowTitle)
                            .font(.caption)
                            .foregroundStyle(Color.mutedGray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Text("\(mapped.containedText.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.3))
                    )
                
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color.mutedGray)
            }
            
            // Expanded text content
            if isSelected {
                Divider()
                    .background(Color.subtleBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(mapped.containedText) { text in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(text.text)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue.opacity(0.5) : Color.subtleBorder, lineWidth: 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}
