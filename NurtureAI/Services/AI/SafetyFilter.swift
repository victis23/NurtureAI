import Foundation

/// Pre-send and post-receive safety filtering for all AI interactions.
final class SafetyFilter {

    // MARK: - Input screening

    enum InputResult {
        case allowed
        case blocked(reason: String)
        case requiresMedicalDisclaimer
    }

    func screenInput(_ text: String) -> InputResult {
        let lower = text.lowercased()

        for trigger in emergencyTriggers {
            if lower.contains(trigger) {
                return .blocked(reason: "This sounds like an emergency. Please call 911 or go to the nearest emergency room immediately.")
            }
        }

        for keyword in medicalKeywords {
            if lower.contains(keyword) {
                return .requiresMedicalDisclaimer
            }
        }

        return .allowed
    }

    // MARK: - Output screening

    func screenOutput(_ text: String) -> String {
        var result = text
        for (unsafe, safe) in replacements {
            result = result.replacingOccurrences(of: unsafe, with: safe, options: .caseInsensitive)
        }
        return result
    }

    func appendDisclaimerIfNeeded(to response: String, for input: String) -> String {
        let lower = input.lowercased()
        let needsDisclaimer = medicalKeywords.contains { lower.contains($0) }
        guard needsDisclaimer else { return response }
        return response + "\n\n*Always consult your pediatrician for medical advice specific to your baby.*"
    }

    // MARK: - Private

    private let emergencyTriggers = [
        "not breathing", "stopped breathing", "turning blue", "lips turning blue",
        "unconscious", "won't wake up", "seizure", "convulsion",
        "severe allergic", "anaphylaxis", "fell from",
    ]

    private let medicalKeywords = [
        "fever", "temperature", "sick", "vomiting", "diarrhea",
        "rash", "jaundice", "yellow", "medication", "medicine",
        "dose", "dosage", "allergy", "allergic", "infection",
        "vaccine", "shot", "milestone", "development",
    ]

    private let replacements: [(String, String)] = [
        ("you should give your baby", "you may want to consider giving your baby (consult your pediatrician)"),
        ("diagnose", "help identify"),
        ("prescribe", "suggest discussing with your doctor"),
    ]
}
