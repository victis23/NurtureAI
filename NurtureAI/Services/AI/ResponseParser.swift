import Foundation

/// Parses structured data out of AI free-text responses where applicable.
final class ResponseParser {

    struct ParsedResponse {
        let displayText: String
        let suggestedActions: [SuggestedAction]
        let urgencyLevel: UrgencyLevel
    }

    enum UrgencyLevel {
        case normal
        case advisory
        case urgent
    }

    struct SuggestedAction {
        let label: String
        let type: ActionType

        enum ActionType {
            case logFeeding
            case logSleep
            case logDiaper
            case callDoctor
            case callEmergency
            case setReminder(TimeInterval)
        }
    }

    func parse(_ rawText: String) -> ParsedResponse {
        let urgency = detectUrgency(rawText)
        let actions = extractActions(rawText)
        return ParsedResponse(
            displayText: rawText,
            suggestedActions: actions,
            urgencyLevel: urgency
        )
    }

    private func detectUrgency(_ text: String) -> UrgencyLevel {
        let lower = text.lowercased()
        if lower.contains("call 911") || lower.contains("emergency room") || lower.contains("immediately") {
            return .urgent
        }
        if lower.contains("consult your pediatrician") || lower.contains("see a doctor") || lower.contains("call your doctor") {
            return .advisory
        }
        return .normal
    }

    private func extractActions(_ text: String) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []
        let lower = text.lowercased()

        if lower.contains("log") && lower.contains("feeding") {
            actions.append(.init(label: "Log Feeding", type: .logFeeding))
        }
        if lower.contains("log") && lower.contains("sleep") {
            actions.append(.init(label: "Log Sleep", type: .logSleep))
        }
        if lower.contains("call your doctor") || lower.contains("call your pediatrician") {
            actions.append(.init(label: "Call Doctor", type: .callDoctor))
        }
        if lower.contains("call 911") || lower.contains("emergency") {
            actions.append(.init(label: "Call 911", type: .callEmergency))
        }
        return actions
    }
}
