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
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
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
    
    // MARK: - Event Management
    
    /// Add a new activity event
    /// - Parameters:
    ///   - source: The source/project name (e.g., "MyProject")
    ///   - type: The event type (e.g., "file_edit", "app_switch")
    ///   - text: The event details (e.g., file path, app name)
    ///   - meta: Optional metadata as JSON string
    ///
    /// **Example Usage:**
    /// ```swift
    /// activityManager.addEvent(
    ///     source: "ECHO-macOS-App",
    ///     type: "file_edit",
    ///     text: "ContentView.swift",
    ///     meta: nil
    /// )
    /// ```
    func addEvent(source: String, type: String, text: String, meta: String? = nil) {
        let newEvent = Event(source: source, type: type, text: text, meta: meta)
        
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
}
