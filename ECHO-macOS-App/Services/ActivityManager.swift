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
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private let ocrEngine = OCREngine()
    private let windowManager = WindowManager()
    
    // MARK: - Initialization
    
    init() {}
    
    /// Configure the manager with a SwiftData context
    /// - Parameter context: The ModelContext for data persistence
    func configure(with context: ModelContext) {
        self.modelContext = context
        fetchTodayEvents()
        startTracking()
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
    
    /// Process OCR results into events (optional - for future automatic tracking)
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
