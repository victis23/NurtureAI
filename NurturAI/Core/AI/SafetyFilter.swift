import Foundation

struct SafetyFilter {

    func requiresEmergencyResponse(_ query: String) -> Bool {
        let lower = query.lowercased()
        return emergencyPatterns.contains { lower.contains($0) }
    }

    func requiresDoctorEscalation(_ query: String) -> Bool {
        let lower = query.lowercased()
        return doctorPatterns.contains { lower.contains($0) }
    }

    private let emergencyPatterns: [String] = [
        "not breathing", "stopped breathing", "can't breathe",
        "blue lips", "blue face", "turning blue",
        "unconscious", "won't wake up", "unresponsive",
        "seizure", "convulsion", "shaking uncontrollably",
        "fever under 3 months", "high fever newborn",
        "severe bleeding", "head injury", "fell off",
        "swallowed", "choking", "purple"
    ]

    private let doctorPatterns: [String] = [
        "fever", "blood in stool", "bloody stool",
        "rash spreading", "not eating", "feeding strike",
        "ear pulling", "eye discharge", "yellow skin",
        "jaundice", "diarrhea", "vomiting", "projectile"
    ]
}
