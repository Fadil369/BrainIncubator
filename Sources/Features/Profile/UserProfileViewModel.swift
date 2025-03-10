import SwiftUI
import Combine

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var teamMembers: [TeamMember] = []
    @Published var resources: [TeamResource] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedResourceType: TeamResource.ResourceType = .project
    
    private let teamManager: TeamManager
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(teamManager: TeamManager = .shared, authManager: AuthenticationManager = .shared) {
        self.teamManager = teamManager
        self.authManager = authManager
        
        loadUserProfile()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        teamManager.teamMembersPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$teamMembers)
        
        teamManager.resourcesPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$resources)
    }
    
    func loadUserProfile() {
        isLoading = true
        Task {
            do {
                user = try await authManager.getCurrentUser()
                try await teamManager.fetchTeamMembers()
                try await teamManager.fetchResources()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    func updateProfile(name: String) async throws {
        try await authManager.updateUserProfile(displayName: name)
        user = try await authManager.getCurrentUser()
    }
    
    func addTeamMember(email: String, role: TeamRole) async throws {
        try await teamManager.addTeamMember(email: email, role: role)
    }
    
    func removeTeamMember(_ member: TeamMember) async throws {
        try await teamManager.removeTeamMember(member)
    }
    
    func createResource(name: String, description: String) async throws {
        let resource = TeamResource(
            id: UUID().uuidString,
            name: name,
            description: description,
            type: selectedResourceType,
            createdBy: user?.id ?? "",
            createdAt: Date()
        )
        try await teamManager.createResource(resource)
    }
    
    func archiveResource(_ resource: TeamResource) async throws {
        try await teamManager.archiveResource(resource)
    }
}