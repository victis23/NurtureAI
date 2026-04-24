// MARK: - Strings
// Single source of truth for all user-facing text in NurturAI.
//
// Usage:  Text(Strings.Home.title)
//         TextField(Strings.Assist.inputPlaceholder, text: $query)
//
// Localization: when ready, replace each `static let` body with
//   String(localized: "key", defaultValue: "…")
// and generate a Localizable.xcstrings from these keys.

enum Strings {

    // MARK: - Common
    enum Common {
        static let appName          = "NurturAI"
        static let cancel           = "Cancel"
        static let save             = "Save"
        static let edit             = "Edit"
        static let ok               = "OK"
        static let back             = "Back"
        static let close            = "Close"
        static let logNow           = "Log Now"
        static let somethingWrong   = "Something went wrong"
        static let unknownError     = "An unknown error occurred."
        static let noBabyProfile    = "No baby profile"
        static let stop             = "Stop"
    }

    // MARK: - Auth
    enum Auth {
        static let tagline          = "Confident parenting,\none moment at a time."
        static let legalDisclaimer  = "By continuing, you agree to our Terms of Service and Privacy Policy."
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let navigationTitle  = "Welcome to NurturAI"
        static let continueButton   = "Continue"
        static let getStarted       = "Get Started"

        enum Name {
            static let heading      = "What's your baby's name?"
            static let subheading   = "You can always change this later."
            static let placeholder  = "Baby's name"
        }

        enum Birthday {
            static let heading      = "When was your baby born?"
            static let subheading   = "We use this to personalise advice for their age and stage."
            static let pickerLabel  = "Date of birth"
        }

        enum Feeding {
            static let heading      = "How are you feeding?"
            static let subheading   = "NurturAI tailors feed tracking and AI responses to your method."
        }
    }

    // MARK: - Home
    enum Home {
        static let navigationTitle  = "Today"
        static let notLogged        = "Not logged"
        static let feedingsToday    = "feedings today"
        static let askAI            = "Ask AI"
        static let feed             = "Feed"
        static let sleep            = "Sleep"
        static let diaper           = "Diaper"

        enum Status {
            static let lastFed           = "Last Fed"
            static let awake             = "Awake"
            static let sleepToday        = "Sleep Today"
            static let lastDiaper        = "Last Diaper"
            static let currentlyFeeding  = "Currently feeding"
            static let currentlySleeping = "Currently sleeping"
            static func maxAwake(_ value: String) -> String { "Max \(value)m recommended" }
        }

        enum Timer {
            static let feedInProgress   = "Feeding in progress"
            static let sleepInProgress  = "Sleep in progress"
            static let diaperInProgress = "Diaper is being changed"
            static let moodLogged       = "Mood logged"
        }

        enum Prediction {
            static let title        = "Getting tired?"
        }
    }

    // MARK: - Log
    enum Log {
        static let navigationTitle  = "Log"
        static let pickerLabel      = "Log type"
        static let tabFeed          = "Feed"
        static let tabSleep         = "Sleep"
        static let tabDiaper        = "Diaper"
        static let tabMood          = "Mood"
        static func savedConfirmation(_ type: String) -> String { "Logged \(type) ✓" }
        static func moodHeading(_ name: String) -> String { "How is \(name) feeling?" }

        enum Feed {
            static let sideLabel        = "Side"
            static let amountLabel      = "Amount (ml)"
            static let inProgress       = "Feeding in progress"
            static let readyToStart     = "Ready to start"
            static let stopFeed         = "Stop Feed"
            static let startFeed        = "Start Feed"
        }

        enum Sleep {
            static let inProgress       = "Sleep in progress"
            static let readyToStart     = "Ready to start"
            static let wakeUp           = "Wake Up"
            static let startSleep       = "Start Sleep"
        }

        enum Diaper {
            static let typeLabel        = "Diaper type"
        }
    }

    // MARK: - History
    enum History {
        static let navigationTitle  = "History"
        static let noLogsTitle      = "No logs yet"
        static let noLogsMessage    = "Start logging feeds, sleep, and diapers."
        static let today            = "Today"
        static let yesterday        = "Yesterday"
    }

    // MARK: - Assist
    enum Assist {
        static let navigationTitle      = "Ask NurturAI"
        static let freeLeft             = "free left"
        static let loadingMessage       = "Looking into this…"
        static let askAnother           = "Ask another question"
        static let inputPlaceholder     = "Describe what's happening right now..."
        static let errorFallback        = "An error occurred."
        static let doctorEscalation     = "This question may relate to a condition worth discussing with your pediatrician."

        enum Response {
            static let lowConfidenceNote    = "Lower confidence — there may be less information available for this situation."
            static let monitorHeading       = "Keep an eye on:"
        }

        enum QuickPicks {
            static let crying       = "Crying"
            static let wontSleep    = "Won't sleep"
            static let feedingIssue = "Feeding issue"
            static let rash         = "Rash"
            static let fever        = "Fever"
            static let gasFussiness = "Gas/Fussiness"
        }

        enum Escalation {
            static let emergencyHeading     = "SEEK EMERGENCY CARE"
            static let emergencySubheading  = "or call 911 immediately"
            static let doctorHeading        = "Consider calling your pediatrician if:"
        }

        enum Feedback {
            static let prompt       = "Did this help?"
        }
    }

    // MARK: - Settings
    enum Settings {
        static let navigationTitle      = "Settings"

        enum BabyProfile {
            static let sectionTitle     = "Baby Profile"
            static let nameLabel        = "Name"
            static let birthdayLabel    = "Birthday"
        }

        enum Subscription {
            static let sectionTitle     = "Subscription"
            static let proPlan          = "Pro Plan"
            static let freePlan         = "Free Plan"
            static let proDescription   = "Unlimited AI queries"
            static let freeDescription  = "3 AI queries per day"
            static let upgradeToPro     = "Upgrade to Pro"
        }

        enum Caregivers {
            static let sectionTitle         = "Caregivers"
            static let addCaregiver         = "Add Caregiver"
            static let pendingFeatureTitle  = "Coming Soon!"
        }

        enum Legal {
            static let sectionTitle     = "Legal"
            static let privacyPolicy    = "Privacy Policy"
            static let termsOfService   = "Terms of Service"
        }

        enum Account {
            static let signOut          = "Sign Out"
			static let deleteAccount     = "Delete Account"
			static let sectionTitle = "Account Management"

			// Re-auth confirmation flow (run before any destructive delete work)
			static let reauthTitle       = "Confirm It's You"
			static let reauthMessage     = "For your security, please sign in with Apple again. Nothing will be deleted until this succeeds."
			static let reauthCancel      = "Not Now"
			static let deleteAlertTitle  = "Delete Account?"
			static let deleteAlertBody   = "You'll be asked to sign in with Apple to confirm. This permanently deletes your account, your baby profile, and all logged data. It cannot be undone."
			static let deleteConfirm     = "Continue"
        }
    }

    // MARK: - Paywall
    enum Paywall {
        static let navigationTitle      = "Upgrade"
        static let title                = "NurturAI Pro"
        static let subtitle             = "Unlimited AI questions, priority responses,\nand caregiver sharing."
        static let bestValue            = "BEST VALUE"
        static let restorePurchases     = "Restore Purchases"
        static let footer               = "Prices shown in USD. Cancel anytime."
    }

    // MARK: - Products
    enum Products {
        static let proMonthlyName       = "Pro Monthly"
        static let proAnnualName        = "Pro Annual"
        static let familyAnnualName     = "Family Annual"
        static let proMonthlyPrice      = "$14.99/mo"
        static let proAnnualPrice       = "$99.00/yr"
        static let familyAnnualPrice    = "$149.00/yr"
    }

    // MARK: - Enums Display
    enum FeedingMethod {
        static let breast   = "Breastfeeding"
        static let formula  = "Formula"
        static let combo    = "Combo"
    }

    enum Mood {
        static let content  = "Content"
        static let fussy    = "Fussy"
        static let crying   = "Crying"
        static let settled  = "Settled"
        static let sleeping = "Sleeping"
    }

    // MARK: - Notifications
    /// User-facing copy for local UNNotification reminders.
    /// All "primary" copy fires when a feed/sleep/diaper window is reached;
    /// "followup" copy fires `NotificationService.followupDelayMinutes` later if ignored.
    enum Notifications {

        enum Feed {
            static func primaryTitle(_ babyName: String) -> String {
                "Time to feed \(babyName)"
            }
            static func primaryBody(_ minutesAgo: Int) -> String {
                "It's been \(minutesAgo) min since the last feeding."
            }
            static func followupTitle(_ babyName: String) -> String {
                "\(babyName) still needs to be fed"
            }
            static let followupBody = "It's been a while since the last feeding — don't forget to log it."
        }

        enum Sleep {
            static func primaryTitle(_ babyName: String) -> String {
                "\(babyName) may be getting tired"
            }
            static func primaryBody(_ babyName: String, awakeMinutes: Int, maxMinutes: Int) -> String {
                "\(babyName) has been awake for \(awakeMinutes) min — approaching the \(maxMinutes) min limit."
            }
            static func followupTitle(_ babyName: String) -> String {
                "\(babyName) is past their awake window"
            }
            static let followupBody = "Overtired babies struggle to fall asleep — try winding down soon."
        }

        enum Diaper {
            static func primaryTitle(_ babyName: String) -> String {
                "Time to check \(babyName)'s diaper"
            }
            static func primaryBody(_ minutesAgo: Int) -> String {
                "It's been \(minutesAgo) min since the last diaper change."
            }
            static func followupTitle(_ babyName: String) -> String {
                "\(babyName)'s diaper still needs checking"
            }
            static let followupBody = "Don't forget to check and log a diaper change."
        }
    }

    // MARK: - Errors
    enum Errors {
        enum App {
            static let dataError        = "A data error occurred. Please try again."
            static let networkError     = "A network error occurred. Check your connection and try again."
            static let unknownError     = "An unexpected error occurred. Please try again."
            static let aiRecovery       = "Check your internet connection or try a different question."
            static let dataRecovery     = "Try restarting the app."
            static let networkRecovery  = "Check your internet connection."
            static let unknownRecovery  = "If the problem persists, please restart the app."
        }

        enum AI {
            static let invalidResponse  = "The AI service returned an unexpected response."
            static func httpError(_ code: Int) -> String { "The AI service returned an error (HTTP \(code))." }
            static let parseError       = "Could not understand the AI response. Please try again."
            static let contextUnavailable = "Baby context could not be loaded. Please try again."
        }

        enum Auth {
            static let invalidCredential   = "Sign in failed. Please try again."
            static let notSignedIn         = "You must be signed in to perform this action."
            static let requiresRecentLogin = "For your security, please sign in again before deleting your account."
        }

        enum Subscription {
            static let productNotFound      = "Product not found. Please try again later."
            static let verificationFailed   = "Purchase could not be verified."
            static let pending              = "Your purchase is pending approval."
            static let unknown              = "An unknown error occurred."
        }

        enum Onboarding {
            static let saveFailed       = "Could not save baby profile. Please try again."
        }
    }
}
