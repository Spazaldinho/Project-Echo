import SwiftUI

struct ProfileView: View {
    @State private var userName = "John Doe"
    @State private var userTitle = "Full-Stack Developer"
    @State private var userEmail = "john@example.com"
    @State private var showingEditProfile = false
    
    // Temporary state for editing
    @State private var editName = ""
    @State private var editTitle = ""
    @State private var editEmail = ""
    
    var userInitials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "JD"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                HStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(userInitials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(userTitle)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            Label(userEmail, systemImage: "envelope")
                            Label("Joined Oct 2025", systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Button("Edit Profile") {
                        editName = userName
                        editTitle = userTitle
                        editEmail = userEmail
                        showingEditProfile = true
                    }
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
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.subtleBorder, lineWidth: 1)
                        )
                )
                
                // Stats Row
                HStack(spacing: 20) {
                    ProfileStatCard(icon: "clock", value: "257h", label: "Total Time Tracked", color: .blue)
                    ProfileStatCard(icon: "flame", value: "12 days", label: "Active Streak", color: .orange)
                }
                
                // Weekly Graph
                VStack(alignment: .leading, spacing: 20) {
                    Text("This Week")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        GraphBar(day: "Mon", height: 80, active: true)
                        GraphBar(day: "Tue", height: 60, active: true)
                        GraphBar(day: "Wed", height: 100, active: true)
                        GraphBar(day: "Thu", height: 70, active: true)
                        GraphBar(day: "Fri", height: 50, active: true)
                        GraphBar(day: "Sat", height: 10, active: false)
                        GraphBar(day: "Sun", height: 10, active: false)
                    }
                    .frame(height: 120)
                    .padding(.top, 10)
                    
                    Text("You've tracked 28 hours this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.subtleBorder, lineWidth: 1)
                        )
                )
                
                // Achievements
                VStack(alignment: .leading, spacing: 16) {
                    Text("Achievements")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        AchievementCard(icon: "medal", title: "Early Adopter", desc: "Joined during beta", unlocked: true)
                        AchievementCard(icon: "stopwatch", title: "100 Hours", desc: "Tracked 100 hours of work", unlocked: true)
                        AchievementCard(icon: "arrow.triangle.branch", title: "Commit Champion", desc: "Made 100 commits in a month", unlocked: true)
                        AchievementCard(icon: "moon.stars", title: "Night Owl", desc: "Worked after midnight 10 times", unlocked: false)
                        AchievementCard(icon: "flame.fill", title: "Streak Master", desc: "7 day tracking streak", unlocked: false)
                        AchievementCard(icon: "brain.head.profile", title: "Deep Focus", desc: "4 hour uninterrupted session", unlocked: false)
                    }
                }
            }
            .padding(30)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet(
                name: $editName,
                title: $editTitle,
                email: $editEmail,
                onSave: {
                    userName = editName
                    userTitle = editTitle
                    userEmail = editEmail
                    showingEditProfile = false
                },
                onCancel: {
                    showingEditProfile = false
                }
            )
        }
    }
}

struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.subtleBorder, lineWidth: 1)
                )
        )
    }
}

struct GraphBar: View {
    let day: String
    let height: CGFloat
    let active: Bool
    
    var body: some View {
        VStack {
            Text(day)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(active ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2))
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementCard: View {
    let icon: String
    let title: String
    let desc: String
    let unlocked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(unlocked ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(unlocked ? .blue : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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
        .opacity(unlocked ? 1.0 : 0.6)
    }
}
