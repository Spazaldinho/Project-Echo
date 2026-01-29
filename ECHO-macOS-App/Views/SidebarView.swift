import SwiftUI
import Combine

// MARK: - Color Theme
extension Color {
    static let sidebarBackground = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let cardBackground = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let contentBackground = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let mutedGray = Color(red: 0.50, green: 0.50, blue: 0.55)
    static let subtleBorder = Color.white.opacity(0.12)
    static let glassFill = Color.white.opacity(0.08)
    static let glassStroke = Color.white.opacity(0.15)
}

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case timeline = "Timeline"
    case screenCapture = "Screen Capture"
    case ask = "Ask"
    case projects = "Projects"
    case settings = "Settings"
    case profile = "Profile"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .timeline: return "chart.xyaxis.line"
        case .screenCapture: return "camera.viewfinder"
        case .ask: return "magnifyingglass"
        case .projects: return "folder"
        case .settings: return "gearshape"
        case .profile: return "person"
        }
    }
}

struct SidebarView: View {
    @Bindable var activityManager: ActivityManager
    @Binding var selection: NavigationItem?
    
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable Content Region
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo from Assets
                    Image("ECHOLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                        .opacity(0.9)
                        .padding(.top, 24)
                        .padding(.bottom, 36)
                    
                    // Navigation
                    VStack(spacing: 8) {
                        ForEach(NavigationItem.allCases) { item in
                            SidebarRow(item: item, isSelected: selection == item) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selection = item
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()
            
            // Status Card with glass effect
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(activityManager.isTracking ? Color.green.opacity(0.9) : Color.orange.opacity(0.8))
                            .frame(width: 10, height: 10)
                            .shadow(color: activityManager.isTracking ? Color.green.opacity(0.5) : .clear, radius: 4)
                        Text(activityManager.isTracking ? "Tracking Active" : "Tracking Paused")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    Text("\(activityManager.stats.events) events ready to be\ncompiled")
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.mutedGray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Last: 2 minutes ago")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.mutedGray.opacity(0.7))
                        .padding(.top, 2)
                }
                
                HStack(spacing: 6) {
                    // Pause/Resume Button
                    Button {
                        if activityManager.isTracking {
                            activityManager.stopTracking()
                        } else {
                            activityManager.startTracking()
                        }
                    } label: {
                        Text(activityManager.isTracking ? "Pause" : "Resume")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .frame(minWidth: 55)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                Color.clear
                                    .glassEffect()
                                    .clipShape(Capsule())
                            }
                    }
                    .buttonStyle(.plain)
                    
                    // Settings Button
                    Button {
                        selection = .settings
                    } label: {
                        Text("Settings")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                Color.clear
                                    .glassEffect()
                                    .clipShape(Capsule())
                            }
                    }
                    .buttonStyle(.plain)
                    
                    // Compile Button (accent)
                    Button {
                        // Compile action placeholder
                    } label: {
                        Text("Compile")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                Capsule()
                                    .fill(Color.blue.opacity(0.5))
                                    .glassEffect()
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.subtleBorder, lineWidth: 1)
                    )
            )
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sidebarBackground.ignoresSafeArea())
        .onReceive(timer) { input in
            now = input
        }
    }
}

// MARK: - Sidebar Row Component
struct SidebarRow: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 22)
                Text(item.rawValue)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .foregroundStyle(isSelected ? .white : (isHovered ? .white : Color.mutedGray))
            .background {
                if isSelected || isHovered {
                    Color.clear
                        .glassEffect()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}


