import Foundation

// MARK: - Week 4 Stub: Caregiver invite / shared access

protocol CaregiverServiceProtocol {
    func sendInvite(email: String, for baby: Baby) async throws
    func acceptInvite(code: String) async throws
    func revokeAccess(caregiverID: UUID, for baby: Baby) async throws
    func fetchCaregivers(for baby: Baby) async throws -> [Caregiver]
}

struct Caregiver: Identifiable {
    let id: UUID
    let name: String
    let email: String
    let role: Role

    enum Role: String {
        case primary = "Primary"
        case secondary = "Secondary"
        case readOnly = "View Only"
    }
}

// Stub — replace with CloudKit / server implementation in Week 4
final class StubCaregiverService: CaregiverServiceProtocol {
    func sendInvite(email: String, for baby: Baby) async throws {}
    func acceptInvite(code: String) async throws {}
    func revokeAccess(caregiverID: UUID, for baby: Baby) async throws {}
    func fetchCaregivers(for baby: Baby) async throws -> [Caregiver] { [] }
}
