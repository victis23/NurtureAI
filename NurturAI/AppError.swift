import Foundation

enum AppError: LocalizedError {
    case ai(AIError)
    case data(Error)
    case network(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .ai(let aiError):
            return aiError.errorDescription
        case .data:
            return "A data error occurred. Please try again."
        case .network:
            return "A network error occurred. Check your connection and try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .ai:
            return "Check your internet connection or try a different question."
        case .data:
            return "Try restarting the app."
        case .network:
            return "Check your internet connection."
        case .unknown:
            return "If the problem persists, please restart the app."
        }
    }
}
