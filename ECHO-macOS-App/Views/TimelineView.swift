import SwiftUI

struct TimelineView: View {
    @Bindable var activityManager: ActivityManager
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var filter: String = "All"
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // Filter events for the selected date
    var filteredEvents: [Event] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return activityManager.events.filter { event in
            event.timestamp >= startOfDay && event.timestamp < endOfDay
        }
    }
    
    // Convert Events to TimelineEvents for display
    var timelineEvents: [TimelineEvent] {
        filteredEvents.map { event in
            TimelineEvent(
                time: event.timestamp.formatted(date: .omitted, time: .shortened),
                duration: "Active",
                title: event.type.replacingOccurrences(of: "_", with: " ").capitalized,
                desc: event.text,
                type: mapEventType(event.type),
                originalEvent: event
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Timeline")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("A chronological view of your daily activities and work sessions")
                    .foregroundStyle(.secondary)
            }
            
            // Toolbar
            HStack {
                HStack(spacing: 12) {
                    // Date Picker Button
                    Button(action: {
                        showDatePicker.toggle()
                    }) {
                        Label(dateFormatter.string(from: selectedDate), systemImage: "calendar")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.subtleBorder, lineWidth: 1)
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDatePicker) {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                    }
                    
                    HStack(spacing: 4) {
                        // Previous Day
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        
                        // Today Button
                        Button(action: {
                            selectedDate = Date()
                        }) {
                            Text(isToday ? "Today" : "Today")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isToday ? .blue : .primary)
                        
                        // Next Day
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Label("Filter", systemImage: "line.3.horizontal.decrease")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.subtleBorder, lineWidth: 1)
                                )
                        }
                }
                .buttonStyle(.plain)
            }
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .blue, label: "Code")
                LegendItem(color: .green, label: "Research")
                LegendItem(color: .red, label: "Meetings")
                LegendItem(color: .purple, label: "Design")
            }
            
            // List
            ScrollView {
                if timelineEvents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .padding(.top, 60)
                        Text("No events for this day")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(isToday ? "Enable auto-capture in Settings to start tracking" : "No activity recorded for this date")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ZStack(alignment: .topLeading) {
                        // Vertical Line
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2)
                            .padding(.leading, 64)
                            .padding(.top, 20)
                        
                        VStack(spacing: 0) {
                            ForEach(timelineEvents) { activity in
                                TimelineRowItem(activity: activity)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .padding(30)
        .background(Color.contentBackground)
    }
    
    // Map event type strings to TimelineEvent.ActivityType
    private func mapEventType(_ type: String) -> TimelineEvent.ActivityType {
        switch type.lowercased() {
        case "coding", "ocr_detection":
            return .code
        case "browsing":
            return .research
        case "communication":
            return .meeting
        case "design", "writing":
            return .design
        default:
            return .code
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct TimelineRowItem: View {
    let activity: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time
            Text(activity.time)
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
                .padding(.top, 14)
            
            // Dot
            Circle()
                .fill(activity.color)
                .frame(width: 10, height: 10)
                .background(Color(nsColor: .windowBackgroundColor))
                .padding(.top, 20)
                .zIndex(1)
            
            // Card - Using solid background instead of glass effect
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(activity.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(activity.duration)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Text(activity.desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(activity.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.bottom, 16)
        }
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let time: String
    let duration: String
    let title: String
    let desc: String
    let type: ActivityType
    let originalEvent: Event?
    
    enum ActivityType {
        case code, research, meeting, design
    }
    
    var color: Color {
        switch type {
        case .code: return .blue
        case .research: return .green
        case .meeting: return .red
        case .design: return .purple
        }
    }
}
