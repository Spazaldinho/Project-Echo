import SwiftUI

struct AskView: View {
    @State private var query: String = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Ask ECHO")
                    .font(.system(size: 32, weight: .bold))
                Text("Query your activity data using natural language")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Spacer().frame(height: 20)
            
            // Sparkle Icon (Placeholder for the gradient icon in screenshot)
            Image(systemName: "sparkles")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(.cyan)
                .padding(20)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text("What would you like to know?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ask questions about your work activity, productivity\npatterns, or time allocation")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            // Preset Questions
            VStack(spacing: 12) {
                PromptButton(icon: "clock", title: "Time spent coding today", subtitle: "Get a breakdown of your coding sessions")
                PromptButton(icon: "doc.text", title: "Most edited files this week", subtitle: "See which files you've worked on most")
                PromptButton(icon: "chart.bar", title: "Productivity trends", subtitle: "Analyze your work patterns over time")
            }
            .frame(maxWidth: 500)
            
            Spacer()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask about your activity...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.body)
                
                Button(action: {}) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background {
                            Color.blue.opacity(0.5)
                                .glassEffect()
                                .clipShape(Circle())
                        }
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background {
                Color.clear
                    .glassEffect()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: 600)
            .padding(.bottom, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PromptButton: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background {
                Color.clear
                    .glassEffect()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .buttonStyle(.plain)
    }
}
