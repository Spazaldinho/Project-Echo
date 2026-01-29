import SwiftUI

struct EditProfileSheet: View {
    @Binding var name: String
    @Binding var title: String
    @Binding var email: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            Divider()
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter your name", text: $name)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.subtleBorder, lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Job Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter your job title", text: $title)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.subtleBorder, lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.subtleBorder, lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.subtleBorder, lineWidth: 1)
                        )
                )
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Save Changes") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || email.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill((name.isEmpty || email.isEmpty) ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5))
                        .glassEffect()
                }
                .buttonStyle(.plain)
                .opacity((name.isEmpty || email.isEmpty) ? 0.5 : 1.0)
            }
            .padding(24)
        }
        .frame(width: 500, height: 400)
        .background(Color.contentBackground)
    }
}
