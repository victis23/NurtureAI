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
            return Strings.Errors.App.dataError
        case .network:
            return Strings.Errors.App.networkError
        case .unknown:
            return Strings.Errors.App.unknownError
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .ai:
            return Strings.Errors.App.aiRecovery
        case .data:
            return Strings.Errors.App.dataRecovery
        case .network:
            return Strings.Errors.App.networkRecovery
        case .unknown:
            return Strings.Errors.App.unknownRecovery
        }
    }
}
