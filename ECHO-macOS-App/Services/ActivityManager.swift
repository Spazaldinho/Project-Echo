import Foundation
import SwiftData
import SwiftUI

// MARK: - Data Models

/// Statistics for a single day's activity
struct DailyStats {
    var hours: Double = 0
    var projects: Int = 0
    var files: Int = 0
    var events: Int = 0
}

/// Captured screenshot with OCR data, pending compilation
struct CapturedScreenshot: Identifiable {
    let id = UUID()
    let timestamp: Date
    let image: NSImage
    let ocrResults: [OCRResult]
    let mappedWindows: [MappedWindow]
}

// MARK: - Activity Manager

/// Manages activity tracking and statistics
/// 
/// **Backend Integration Guide:**
/// 1. Use `addEvent()` to insert new activity events
/// 2. Call `fetchTodayEvents()` to refresh the event list
/// 3. Access `events` array to display recent activity
/// 4. Access `stats` to display daily statistics
/// 5. Use `isTracking` to control tracking state
/// 6. Use `performScreenCapture()` to trigger OCR and window mapping
@Observable
class ActivityManager {
    // MARK: - Public Properties
    
    /// Array of all events for today
    var events: [Event] = []
    
    /// Calculated statistics for today
    var stats: DailyStats = DailyStats()
    
    /// Currently active file (set by your backend)
    var currentFile: String = ""
    
    /// Currently active project (set by your backend)
    var currentProject: String = ""
    
    /// Whether tracking is currently active
    var isTracking: Bool = false
    
    // OCR-related properties
    /// Latest OCR results from screen capture
    var ocrResults: [OCRResult] = []
    
    /// Latest mapped windows with their contained text
    var mappedWindows: [MappedWindow] = []
    
    /// Latest captured screenshot
    var capturedImage: NSImage?
    
    // Automatic capture properties
    /// Whether automatic capture is currently active
    var isAutoCapturing: Bool = false
    
    /// Capture interval in seconds (default: 5 seconds, range: 5s - 1min)
    var captureInterval: TimeInterval = 5
    
    /// Whether to automatically generate events from captures (disabled for compile-based workflow)
    var autoGenerateEvents: Bool = false
    
    // Pending screenshots (before compilation)
    /// Array of screenshots captured but not yet compiled into events
    var pendingScreenshots: [CapturedScreenshot] = []
    
    /// Count of pending screenshots ready to be compiled
    var pendingCount: Int {
        pendingScreenshots.count
    }
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private let ocrEngine = OCREngine()
    private let windowManager = WindowManager()
    private var captureTimer: Timer?
    
    // Track recent events to prevent duplicates
    private var recentEventKeys: Set<String> = []
    private let deduplicationWindow: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init() {}
    
    /// Configure the manager with a SwiftData context
    /// - Parameter context: The ModelContext for data persistence
    func configure(with context: ModelContext) {
        self.modelContext = context
        fetchTodayEvents()
        startTracking()
        
        // Start auto-capture by default for compile-based workflow
        Task { @MainActor in
            startAutoCapture()
        }
    }
    
    // MARK: - Tracking Control
    
    /// Start activity tracking
    func startTracking() {
        isTracking = true
        // TODO: Backend team - implement your tracking logic here
    }
    
    /// Stop activity tracking
    func stopTracking() {
        isTracking = false
        // TODO: Backend team - implement your tracking cleanup here
    }
    
    // MARK: - Event Management (see OCR Methods section for enhanced addEvent)
    
    /// Clear all events from the database (useful for testing/development)
    func clearAllEvents() {
        guard let context = modelContext else {
            print("⚠️ ModelContext not configured")
            return
        }
        
        do {
            try context.delete(model: Event.self)
            events.removeAll()
            recalculateStats()
            print("✅ All events cleared")
        } catch {
            print("❌ Failed to clear events: \(error)")
        }
    }
    
    /// Fetch all events for today from the database
    func fetchTodayEvents() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<Event> { event in
            event.timestamp >= startOfDay && event.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<Event>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        
        do {
            events = try context.fetch(descriptor)
            recalculateStats()
        } catch {
            print("❌ Failed to fetch events: \(error)")
        }
    }
    
    // MARK: - Statistics Calculation
    
    /// Recalculate daily statistics based on current events
    private func recalculateStats() {
        if events.isEmpty {
            stats = DailyStats()
            return
        }
        
        // Calculate total active hours
        var totalSeconds: TimeInterval = 0
        if events.count > 1 {
            let sortedEvents = events.sorted { $0.timestamp < $1.timestamp }
            
            for i in 0..<sortedEvents.count - 1 {
                let diff = sortedEvents[i+1].timestamp.timeIntervalSince(sortedEvents[i].timestamp)
                // Only count gaps less than 1 hour as continuous work
                if diff < 60 * 60 {
                    totalSeconds += diff
                }
            }
        }
        
        let hours = totalSeconds / 3600.0
        let uniqueProjects = Set(events.map { $0.source }).count
        let uniqueFiles = Set(events.map { $0.text }).count
        
        stats = DailyStats(
            hours: (hours * 10).rounded() / 10,
            projects: uniqueProjects,
            files: uniqueFiles,
            events: events.count
        )
    }
    
    // MARK: - Statistics Calculation
    
    /// Calculate total hours tracked across all events
    func calculateTotalHours() -> Double {
        guard !events.isEmpty else { return 0 }
        
        // Group events by day and calculate hours for each day
        let calendar = Calendar.current
        let eventsByDay = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.timestamp)
        }
        
        var totalHours = 0.0
        for (_, dayEvents) in eventsByDay {
            let sortedEvents = dayEvents.sorted { $0.timestamp < $1.timestamp }
            if let first = sortedEvents.first, let last = sortedEvents.last {
                let duration = last.timestamp.timeIntervalSince(first.timestamp)
                totalHours += duration / 3600.0
            }
        }
        
        return totalHours
    }
    
    /// Calculate hours worked this week
    func calculateWeeklyHours() -> Double {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        
        let weekEvents = events.filter { $0.timestamp >= weekStart }
        
        let eventsByDay = Dictionary(grouping: weekEvents) { event in
            calendar.startOfDay(for: event.timestamp)
        }
        
        var weeklyHours = 0.0
        for (_, dayEvents) in eventsByDay {
            let sortedEvents = dayEvents.sorted { $0.timestamp < $1.timestamp }
            if let first = sortedEvents.first, let last = sortedEvents.last {
                let duration = last.timestamp.timeIntervalSince(first.timestamp)
                weeklyHours += duration / 3600.0
            }
        }
        
        return weeklyHours
    }
    
    /// Calculate consecutive days with activity (work streak)
    func calculateWorkStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Get all unique days with events
        let daysWithEvents = Set(events.map { event in
            calendar.startOfDay(for: event.timestamp)
        })
        
        // Count backwards from today
        while daysWithEvents.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streak
    }
    
    /// Get events for a specific date
    func getEvents(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    // MARK: - Automatic Capture Control
    
    /// Start automatic screen capture at the configured interval
    @MainActor
    func startAutoCapture() {
        guard !isAutoCapturing else { return }
        
        isAutoCapturing = true
        
        // Perform initial capture
        Task {
            await performAutomaticCapture()
        }
        
        // Schedule periodic captures
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performAutomaticCapture()
            }
        }
        
        print("✅ Auto-capture started (interval: \(captureInterval)s)")
    }
    
    /// Stop automatic screen capture
    @MainActor
    func stopAutoCapture() {
        guard isAutoCapturing else { return }
        
        isAutoCapturing = false
        captureTimer?.invalidate()
        captureTimer = nil
        
        print("⏹️ Auto-capture stopped")
    }
    
    /// Update the capture interval and restart timer if active
    @MainActor
    func updateCaptureInterval(_ interval: TimeInterval) {
        captureInterval = interval
        
        if isAutoCapturing {
            stopAutoCapture()
            startAutoCapture()
        }
    }
    
    /// Perform automatic capture and store screenshot for later compilation
    @MainActor
    private func performAutomaticCapture() async {
        await performScreenCapture()
        
        // Store screenshot for compilation instead of generating events immediately
        if let image = capturedImage, !mappedWindows.isEmpty {
            let screenshot = CapturedScreenshot(
                timestamp: Date(),
                image: image,
                ocrResults: ocrResults,
                mappedWindows: mappedWindows
            )
            pendingScreenshots.append(screenshot)
            print("📸 Screenshot captured (\(pendingCount) pending)")
        }
    }
    
    /// Compile all pending screenshots into events
    @MainActor
    func compilePendingScreenshots() {
        guard !pendingScreenshots.isEmpty else {
            print("⚠️ No screenshots to compile")
            return
        }
        
        let count = pendingScreenshots.count
        print("🔄 Compiling \(count) screenshots...")
        
        // Process each pending screenshot
        for screenshot in pendingScreenshots {
            // Temporarily set the current capture data
            capturedImage = screenshot.image
            ocrResults = screenshot.ocrResults
            mappedWindows = screenshot.mappedWindows
            
            // Generate events intelligently
            processOCRResultsIntelligently()
        }
        
        // Clear pending screenshots
        pendingScreenshots.removeAll()
        
        // Refresh today's events to update UI
        fetchTodayEvents()
        
        print("✅ Compilation complete! Generated events from \(count) screenshots")
    }
    
    // MARK: - OCR Methods
    
    /// Perform screen capture and OCR analysis
    @MainActor
    func performScreenCapture() async {
        // Capture the main screen
        guard let image = await windowManager.captureMainScreen() else {
            print("❌ Failed to capture screen")
            return
        }
        
        capturedImage = image
        ocrResults = []
        mappedWindows = []
        
        // Perform OCR on the captured image
        await withCheckedContinuation { continuation in
            ocrEngine.performOCR(on: image) { [weak self] results in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.ocrResults = results
                
                // Get visible windows
                let windows = self.windowManager.getVisibleWindows()
                
                // Map text to windows
                var windowMapping: [UUID: [OCRResult]] = [:]
                
                for textResult in results {
                    let centerX = textResult.bounds.x + textResult.bounds.width / 2
                    let centerY = textResult.bounds.y + textResult.bounds.height / 2
                    let pointInPoints = CGPoint(x: centerX, y: centerY)
                    
                    // Find the topmost window containing this text
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
                
                self.mappedWindows = tempMapped.sorted { $0.containedText.count > $1.containedText.count }
                
                print("✅ OCR complete: \(results.count) text items, \(tempMapped.count) windows")
                continuation.resume()
            }
        }
    }
    
    /// Process OCR results into events (basic - creates event for each text)
    func processOCRResults() {
        for mapped in mappedWindows {
            for text in mapped.containedText {
                // Create an event for each detected text
                let boundsJSON = "{\"x\":\(text.bounds.x),\"y\":\(text.bounds.y),\"width\":\(text.bounds.width),\"height\":\(text.bounds.height)}"
                
                addEvent(
                    source: mapped.window.ownerName,
                    type: "ocr_detection",
                    text: text.text,
                    meta: nil,
                    windowName: mapped.window.displayName,
                    ocrText: text.text,
                    bounds: boundsJSON
                )
            }
        }
    }
    
    /// Intelligently process OCR results to create meaningful, deduplicated events
    private func processOCRResultsIntelligently() {
        guard !mappedWindows.isEmpty else { return }
        
        // Get the window with the most text (likely the active/focused window)
        guard let primaryWindow = mappedWindows.first else { return }
        
        // Create a unique key for this window state
        let windowKey = "\(primaryWindow.window.ownerName)_\(primaryWindow.window.windowTitle)"
        
        // Check if we've recently created an event for this window
        if recentEventKeys.contains(windowKey) {
            return // Skip duplicate
        }
        
        // Add to recent events
        recentEventKeys.insert(windowKey)
        
        // Clean up old entries (older than deduplication window)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(deduplicationWindow * 1_000_000_000))
            recentEventKeys.remove(windowKey)
        }
        
        // Determine event type based on application
        let eventType = determineEventType(for: primaryWindow.window.ownerName)
        
        // Get a meaningful text snippet (first substantial text or window title)
        let meaningfulText = primaryWindow.containedText
            .first(where: { $0.text.count > 10 })?.text
            ?? primaryWindow.window.windowTitle
            ?? primaryWindow.window.ownerName
        
        // Create the event
        let meta = "{\"textCount\":\(primaryWindow.containedText.count),\"windowCount\":\(mappedWindows.count)}"
        
        addEvent(
            source: primaryWindow.window.ownerName,
            type: eventType,
            text: meaningfulText,
            meta: meta,
            windowName: primaryWindow.window.displayName,
            ocrText: nil,
            bounds: nil
        )
        
        print("📝 Created event: \(eventType) - \(primaryWindow.window.ownerName)")
    }
    
    /// Determine event type based on application name
    private func determineEventType(for appName: String) -> String {
        let lowercased = appName.lowercased()
        
        if lowercased.contains("xcode") || lowercased.contains("code") || lowercased.contains("terminal") {
            return "coding"
        } else if lowercased.contains("safari") || lowercased.contains("chrome") || lowercased.contains("firefox") {
            return "browsing"
        } else if lowercased.contains("slack") || lowercased.contains("teams") || lowercased.contains("zoom") {
            return "communication"
        } else if lowercased.contains("figma") || lowercased.contains("sketch") || lowercased.contains("photoshop") {
            return "design"
        } else if lowercased.contains("notes") || lowercased.contains("notion") || lowercased.contains("obsidian") {
            return "writing"
        } else {
            return "app_usage"
        }
    }
    
    /// Enhanced addEvent with OCR support
    func addEvent(source: String, type: String, text: String, meta: String? = nil, windowName: String? = nil, ocrText: String? = nil, bounds: String? = nil) {
        let newEvent = Event(
            source: source,
            type: type,
            text: text,
            meta: meta,
            windowName: windowName,
            ocrText: ocrText,
            bounds: bounds
        )
        
        guard let context = modelContext else {
            print("⚠️ ModelContext not configured")
            return
        }
        
        context.insert(newEvent)
        events.append(newEvent)
        recalculateStats()
        
        // Update current state
        currentFile = text
        currentProject = source
    }
}
