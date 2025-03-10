import Foundation
import FirebaseFirestore
import FirebaseAuth

class TeamManager: ObservableObject {
    static let shared = TeamManager()
    private let db = Firestore.firestore()
    
    @Published var currentTeam: [TeamMember] = []
    @Published var resources: [TeamResource] = []
    @Published var isLoading = false
    
    private init() {
        loadTeamData()
        loadResources()
    }
    
    func loadTeamData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        db.collection("teams")
            .whereField("managerId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching team: \(error?.localizedDescription ?? "Unknown error")")
                    self?.isLoading = false
                    return
                }
                
                self?.currentTeam = documents.compactMap { document -> TeamMember? in
                    try? document.data(as: TeamMember.self)
                }
                self?.isLoading = false
            }
    }
    
    func loadResources() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        db.collection("resources")
            .whereField("managerId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching resources: \(error?.localizedDescription ?? "Unknown error")")
                    self?.isLoading = false
                    return
                }
                
                self?.resources = documents.compactMap { document -> TeamResource? in
                    try? document.data(as: TeamResource.self)
                }
                self?.isLoading = false
            }
    }
    
    func addTeamMember(_ member: TeamMember) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.userNotFound }
        
        var memberData = try JSONEncoder().encode(member)
        guard var dict = try JSONSerialization.jsonObject(with: memberData) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid member data"])
        }
        dict["managerId"] = userId
        
        try await db.collection("teams").document(member.id).setData(dict)
        AnalyticsManager.shared.trackUserAction(
            action: "team_member_added",
            parameters: ["role": member.role.rawValue]
        )
    }
    
    func updateTeamMember(_ member: TeamMember) async throws {
        let memberData = try JSONEncoder().encode(member)
        guard let dict = try JSONSerialization.jsonObject(with: memberData) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid member data"])
        }
        
        try await db.collection("teams").document(member.id).updateData(dict)
        AnalyticsManager.shared.trackUserAction(
            action: "team_member_updated",
            parameters: ["member_id": member.id]
        )
    }
    
    func removeTeamMember(id: String) async throws {
        try await db.collection("teams").document(id).delete()
        AnalyticsManager.shared.trackUserAction(
            action: "team_member_removed",
            parameters: ["member_id": id]
        )
    }
    
    func createResource(_ resource: TeamResource) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.userNotFound }
        
        var resourceData = try JSONEncoder().encode(resource)
        guard var dict = try JSONSerialization.jsonObject(with: resourceData) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid resource data"])
        }
        dict["managerId"] = userId
        
        try await db.collection("resources").document(resource.id).setData(dict)
        AnalyticsManager.shared.trackUserAction(
            action: "resource_created",
            parameters: ["type": resource.type.rawValue]
        )
    }
    
    func updateResource(_ resource: TeamResource) async throws {
        let resourceData = try JSONEncoder().encode(resource)
        guard let dict = try JSONSerialization.jsonObject(with: resourceData) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid resource data"])
        }
        
        try await db.collection("resources").document(resource.id).updateData(dict)
        AnalyticsManager.shared.trackUserAction(
            action: "resource_updated",
            parameters: ["resource_id": resource.id]
        )
    }
    
    func archiveResource(id: String) async throws {
        try await db.collection("resources").document(id).updateData([
            "status": TeamResource.ResourceStatus.archived.rawValue
        ])
        AnalyticsManager.shared.trackUserAction(
            action: "resource_archived",
            parameters: ["resource_id": id]
        )
    }
}