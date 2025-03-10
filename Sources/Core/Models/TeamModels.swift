import Foundation
import FirebaseFirestore

struct TeamMember: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var role: TeamRole
    var assignedModules: [String]
    var joinDate: Date
    var lastActive: Date
    
    enum TeamRole: String, Codable {
        case admin = "admin"
        case manager = "manager"
        case member = "member"
    }
}

struct TeamResource: Identifiable, Codable {
    var id: String
    var name: String
    var type: ResourceType
    var description: String
    var assignedTo: [String] // Member IDs
    var createdAt: Date
    var updatedAt: Date
    var status: ResourceStatus
    
    enum ResourceType: String, Codable {
        case trainingModule = "training"
        case assessment = "assessment"
        case documentation = "documentation"
        case customResource = "custom"
    }
    
    enum ResourceStatus: String, Codable {
        case active = "active"
        case archived = "archived"
        case draft = "draft"
    }
}