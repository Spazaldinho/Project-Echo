import SwiftUI

struct ProjectsView: View {
    // Ready for backend integration - empty projects array
    @State private var projects: [ProjectItem] = []
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    @State private var newProjectColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Projects")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Track time and activity across your different projects")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: {
                    showingAddProject = true
                }) {
                    Label("New Project", systemImage: "plus")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(Color.blue.opacity(0.5))
                                .glassEffect()
                        }
                }
                .buttonStyle(.plain)
            }
            
            // Stats Grid
            HStack(spacing: 20) {
                ProjectStatCard(value: "\(calculateTotalHours())", label: "Total Hours")
                ProjectStatCard(value: "\(projects.count)", label: "Active Projects")
                ProjectStatCard(value: "\(calculateTotalCommits())", label: "Total Commits")
            }
            
            // Projects List
            ScrollView {
                if projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .padding(.top, 60)
                        Text("No projects yet")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("Click 'New Project' to add your first project")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 16) {
                        ForEach(projects) { project in
                            ProjectRowItem(project: project)
                        }
                    }
                }
            }
        }
        .padding(30)
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet(
                projectName: $newProjectName,
                projectDescription: $newProjectDescription,
                projectColor: $newProjectColor,
                onAdd: {
                    addProject()
                },
                onCancel: {
                    showingAddProject = false
                    resetForm()
                }
            )
        }
    }
    
    private func addProject() {
        let newProject = ProjectItem(
            name: newProjectName,
            desc: newProjectDescription,
            hours: 0,
            files: 0,
            commits: 0,
            color: newProjectColor
        )
        projects.append(newProject)
        showingAddProject = false
        resetForm()
    }
    
    private func resetForm() {
        newProjectName = ""
        newProjectDescription = ""
        newProjectColor = .blue
    }
    
    private func calculateTotalHours() -> Int {
        projects.reduce(0) { $0 + $1.hours }
    }
    
    private func calculateTotalCommits() -> Int {
        projects.reduce(0) { $0 + $1.commits }
    }
}

struct ProjectStatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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

struct ProjectRowItem: View {
    let project: ProjectItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Dot
            Circle()
                .fill(project.color)
                .frame(width: 8, height: 8)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(project.desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if project.name == "ECHO Project" {
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                // Stats
                HStack(spacing: 24) {
                    Label("\(project.hours) hours", systemImage: "clock")
                    Label("\(project.files) files", systemImage: "doc")
                    Label("\(project.commits) commits", systemImage: "arrow.triangle.branch")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
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

struct ProjectItem: Identifiable {
    let id = UUID()
    let name: String
    let desc: String
    let hours: Int
    let files: Int
    let commits: Int
    let color: Color
}

// MARK: - Add Project Sheet

struct AddProjectSheet: View {
    @Binding var projectName: String
    @Binding var projectDescription: String
    @Binding var projectColor: Color
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    let availableColors: [Color] = [.blue, .green, .purple, .orange, .red, .pink, .yellow, .cyan]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Project")
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
                    // Project Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter project name", text: $projectName)
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
                    
                    // Project Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter project description", text: $projectDescription, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...6)
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
                    
                    // Color Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: projectColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        projectColor = color
                                    }
                            }
                        }
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
                
                Button("Add Project") {
                    onAdd()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(projectName.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(projectName.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5))
                        .glassEffect()
                }
                .buttonStyle(.plain)
                .opacity(projectName.isEmpty ? 0.5 : 1.0)
            }
            .padding(24)
        }
        .frame(width: 500, height: 450)
        .background(Color.contentBackground)
    }
}
