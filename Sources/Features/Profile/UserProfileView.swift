import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var showingAddMemberSheet = false
    @State private var showingResourceSheet = false
    @State private var newMemberEmail = ""
    @State private var selectedRole: TeamRole = .member
    @State private var newResourceName = ""
    @State private var newResourceDescription = ""
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                teamSection
                resourcesSection
            }
            .navigationTitle("Profile & Team")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingAddMemberSheet = true }) {
                            Label("Add Team Member", systemImage: "person.badge.plus")
                        }
                        Button(action: { showingResourceSheet = true }) {
                            Label("Create Resource", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMemberSheet) {
                addTeamMemberSheet
            }
            .sheet(isPresented: $showingResourceSheet) {
                createResourceSheet
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .refreshable {
                viewModel.loadUserProfile()
            }
        }
    }
    
    private var profileSection: some View {
        Section("Profile") {
            if let user = viewModel.user {
                Text("Name: \(user.displayName ?? "Not set")")
                Text("Email: \(user.email)")
                Text("Role: Project Manager")
                Text("Subscription: Active")
            }
        }
    }
    
    private var teamSection: some View {
        Section("Team Members") {
            ForEach(viewModel.teamMembers) { member in
                HStack {
                    VStack(alignment: .leading) {
                        Text(member.email)
                            .font(.headline)
                        Text(member.role.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        Task {
                            try await viewModel.removeTeamMember(member)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var resourcesSection: some View {
        Section("Resources") {
            Picker("Resource Type", selection: $viewModel.selectedResourceType) {
                ForEach(TeamResource.ResourceType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            
            ForEach(viewModel.resources.filter { $0.type == viewModel.selectedResourceType }) { resource in
                VStack(alignment: .leading) {
                    Text(resource.name)
                        .font(.headline)
                    Text(resource.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Created: \(resource.createdAt.formatted())")
                        .font(.caption)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task {
                            try await viewModel.archiveResource(resource)
                        }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
            }
        }
    }
    
    private var addTeamMemberSheet: some View {
        NavigationView {
            Form {
                TextField("Email", text: $newMemberEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                
                Picker("Role", selection: $selectedRole) {
                    ForEach(TeamRole.allCases, id: \.self) { role in
                        Text(role.rawValue.capitalized).tag(role)
                    }
                }
            }
            .navigationTitle("Add Team Member")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingAddMemberSheet = false
                },
                trailing: Button("Add") {
                    Task {
                        try await viewModel.addTeamMember(email: newMemberEmail, role: selectedRole)
                        showingAddMemberSheet = false
                        newMemberEmail = ""
                    }
                }
                .disabled(newMemberEmail.isEmpty)
            )
        }
    }
    
    private var createResourceSheet: some View {
        NavigationView {
            Form {
                TextField("Name", text: $newResourceName)
                TextField("Description", text: $newResourceDescription)
                Picker("Type", selection: $viewModel.selectedResourceType) {
                    ForEach(TeamResource.ResourceType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }
            .navigationTitle("Create Resource")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingResourceSheet = false
                },
                trailing: Button("Create") {
                    Task {
                        try await viewModel.createResource(
                            name: newResourceName,
                            description: newResourceDescription
                        )
                        showingResourceSheet = false
                        newResourceName = ""
                        newResourceDescription = ""
                    }
                }
                .disabled(newResourceName.isEmpty)
            )
        }
    }
}