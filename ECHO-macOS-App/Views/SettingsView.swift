import SwiftUI

struct SettingsView: View {
    @Bindable var activityManager: ActivityManager
    
    @AppStorage("autoStart") private var autoStart = true
    @AppStorage("trackKeyboard") private var trackKeyboard = true
    @AppStorage("compileFreq") private var compileFreq = "Every 15 minutes"
    @AppStorage("dailySummary") private var dailySummary = true
    @AppStorage("idleReminders") private var idleReminders = false
    @AppStorage("theme") private var theme = "Dark"
    @AppStorage("anonymousAnalytics") private var anonymousAnalytics = false
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Customize your ECHO experience and tracking preferences")
                        .foregroundStyle(.secondary)
                }
                
                SettingSection(title: "Tracking", description: "Configure how ECHO monitors your activity") {
                    ToggleRow(icon: "display", title: "Auto-start tracking", subtitle: "Begin tracking when you log in", isOn: $autoStart)
                    Divider().opacity(0.5)
                    ToggleRow(icon: "keyboard", title: "Track keyboard activity", subtitle: "Include keystroke patterns in analytics", isOn: $trackKeyboard)
                    Divider().opacity(0.5)
                    PickerRow(icon: "server.rack", title: "Compile frequency", subtitle: "How often to process tracked events", selection: $compileFreq, options: ["Every 15 minutes", "Hourly", "Daily"])
                }
                
                SettingSection(title: "Notifications", description: "Manage alerts and reminders") {
                    ToggleRow(icon: "bell", title: "Daily summary", subtitle: "Receive a summary of your activity each day", isOn: $dailySummary)
                    Divider().opacity(0.5)
                    ToggleRow(icon: "bell.badge", title: "Idle reminders", subtitle: "Get notified after periods of inactivity", isOn: $idleReminders)
                }
                
                SettingSection(title: "Appearance", description: "Customize the look and feel") {
                    PickerRow(icon: "moon", title: "Theme", subtitle: "Choose your preferred color scheme", selection: $theme, options: ["Dark", "Light", "System"])
                }
                
                SettingSection(title: "Privacy & Data", description: "Control your data and privacy settings") {
                    ToggleRow(icon: "shield", title: "Anonymous analytics", subtitle: "Help improve ECHO with anonymous usage data", isOn: $anonymousAnalytics)
                    Divider().opacity(0.5)
                    HStack {
                        Button("Export Data") {}
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.subtleBorder, lineWidth: 1)
                                    )
                            )
                            .buttonStyle(.plain)
                        Button("Delete All Data") {
                            showDeleteConfirmation = true
                        }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.subtleBorder, lineWidth: 1)
                                    )
                            )
                            .buttonStyle(.plain)
                            .confirmationDialog("Delete All Data?", isPresented: $showDeleteConfirmation) {
                                Button("Delete All Events", role: .destructive) {
                                    activityManager.clearAllEvents()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This will permanently delete all tracked events. This action cannot be undone.")
                            }
                    }
                    .padding(.top, 8)
                }
                
            }
            .padding(30)
        }
    }
}

struct SettingSection<Content: View>: View {
    let title: String
    let description: String
    let content: Content
    
    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.subtleBorder, lineWidth: 1)
                    )
            )
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon) // Placeholder for custom icons
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
        .padding(.vertical, 8)
    }
}

struct PickerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .frame(width: 150)
        }
        .padding(.vertical, 8)
    }
}
