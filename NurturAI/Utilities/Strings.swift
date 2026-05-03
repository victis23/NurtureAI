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
		static let done				= "Done"
		static let termsTitle		= "Terms of Use"
		static let privacyTitle		= "Privacy Policy"
		static let viewPrivacyPolicy = "View Privacy Policy"
		static let contactHeading	= "Contact"
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
		
		enum Greeting {
			static let welcome = "Welcome to Nurtur"
			static let welcomeSubTitle = "Your ai parenting helper"

			static let greeting1 = "We know parenting can feel overwhelming—especially when it’s all new. That’s exactly why we created this app."
			
			static let greeting2 = "Our goal is simple: to support you with guidance you can trust, so you can focus on what matters most—your baby."
			static let greeting3 = "Get instant, personalized answers tailored to your child, powered by AI and grounded in real pediatric research. Because you deserve confidence, not guesswork."
		}

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

		enum KidCount {
			static let heading      = "Is this your first child?"
			static let subheading   = "NurturAI tailors tracking and AI responses to your experience level, stress indicators, and other data points."
			static let dataProtectionStatement = "Remember your data will always be protected and confidential."
		}

        enum Support {
            static let heading      = "Do you have someone you can lean on?"
            static let subheading   = "Parenting feels lighter when there's a hand to hold. We'd love to know who's in your corner."
        }

        enum Overwhelm {
            static let heading      = "Have things felt like a lot lately?"
            static let subheading   = "It's okay if they have. Even the gentlest days of parenthood can feel like a lot — there's no judgement here."
        }

        enum Wellbeing {
            static let heading      = "How has your heart been feeling?"
            static let subheading   = "Becoming a parent can stir up emotions that are hard to name. Whatever you share stays private — we'll always meet you with care."
        }

        enum Household {
            static let heading      = "Who's part of your parenting team at home?"
            static let subheading   = "Every family looks different, and we want to support yours just as it is."
        }

        enum Features {
            static let heading      = "What would feel most helpful right now?"
            static let subheading   = "Pick anything that catches your eye — we'll personalize the app to you."
            static let multiSelectHint = "Select all that apply."
        }

        enum InternetUsage {
            static let heading      = "How often do you turn to the internet for answers about your little one?"
            static let subheading   = "We've all done it. Knowing this helps us bring trustworthy info closer to you, so you don't have to dig."
        }

        enum AppDiscovery {
            static let heading      = "How did you find your way to us?"
            static let subheading   = "We're so glad you're here."
        }

        enum Teething {
            static let heading      = "Has teething started yet?"
            static let subheading   = "Those first little teeth bring big feelings — for everyone."
        }

        enum SolidFoods {
            static let heading      = "Has your little one started exploring solid foods?"
            static let subheading   = "Every tiny taste is a milestone. We'll meet you wherever you are."
        }

        enum Pediatrician {
            static let heading      = "How often do you visit the pediatrician?"
            static let subheading   = "We'll tailor reminders and tips to fit your rhythm."
        }

        enum BirthWeight {
            static let heading      = "How much did your little one weigh at birth?"
            static let subheading   = "We use this to gently track growth over time."
            static let placeholder  = "Birth weight"
        }

        enum CurrentWeight {
            static let heading      = "And what was their weight at the last check?"
            static let subheading   = "It's okay if you're not sure — you can always update this later."
            static let placeholder  = "Current weight"
        }

        enum FeedingFreq {
            static let heading      = "How often does your little one feed in a typical day?"
            static let subheading   = "Every baby has their own rhythm — there's no wrong answer."
        }

        enum Challenges {
            static let heading      = "What's been feeling the hardest right now?"
            static let subheading   = "We all have those moments. Knowing this helps us focus where you need us most."
            static let multiSelectHint = "Select all that apply."
        }

        enum Bathing {
            static let heading      = "How often does bath time happen at your house?"
            static let subheading   = "Splashy and daily or weekly and calm — both are perfect."
        }

        enum AIUsage {
            static let heading      = "Have you used AI for parenting support before?"
            static let subheading   = "There's no right or wrong answer — we'll meet you wherever you are."
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
        static let editStartLabel   = "Start"
        static let editEndLabel     = "End"
        static func editTitle(_ type: String) -> String { "Edit \(type)" }
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
        static let loadingProducts      = "Loading subscription options…"
        static let tryAgain             = "Try again"
        static let restored             = "Subscription restored."
        static let noPurchasesFound     = "No previous purchases found."
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

	enum ChildCount {
		static let hasOneKid = "Yes, this is my first kid."
		static let hasManyKids = "No, this isn't my first kid."
	}

    enum FamilySupport {
        static let strong           = "Yes, I have a strong support system"
        static let occasional       = "Sometimes, when I really need it"
        static let noSupport        = "It's mostly on me right now"
        static let preferNotToSay   = "I'd rather not say"
    }

    enum OverwhelmLevel {
        static let rarely           = "Rarely — I feel mostly steady"
        static let sometimes        = "Sometimes, on the harder days"
        static let often            = "Often"
        static let almostAlways     = "Almost always"
        static let preferNotToSay   = "I'd rather not say"
    }

    enum EmotionalWellbeing {
        static let doingOkay        = "I'm doing okay"
        static let someHardDays     = "I have some hard days"
        static let struggling       = "I've been struggling"
        static let preferNotToSay   = "I'd rather not say"
    }

    enum HouseholdType {
        static let twoParent        = "Two parents at home"
        static let singleParent     = "Just me, parenting solo"
        static let coParenting      = "Co-parenting across two homes"
        static let extendedFamily   = "With extended family"
        static let other            = "Something else"
        static let preferNotToSay   = "I'd rather not say"
    }

    enum DesiredFeature {
        static let sleepTracking    = "Sleep tracking"
        static let feedingTracking  = "Feeding tracking"
        static let aiAdvice         = "AI guidance and answers"
        static let milestones       = "Milestone tracking"
        static let growthTracking   = "Growth tracking"
        static let diaperTracking   = "Diaper tracking"
        static let communitySupport = "Community and support"
    }

    enum InternetUsageFrequency {
        static let rarely           = "Rarely"
        static let sometimes        = "Sometimes"
        static let daily            = "Most days"
        static let manyTimesDaily   = "Many times a day"
    }

    enum AppDiscoverySource {
        static let friendOrFamily   = "A friend or family member"
        static let appStore         = "Browsing the App Store"
        static let socialMedia      = "Social media"
        static let advertisement    = "An ad"
        static let webSearch        = "A web search"
        static let other            = "Somewhere else"
    }

    enum TeethingStatus {
        static let teething         = "Yes, we're in it"
        static let notYet           = "Not yet"
        static let unsure           = "I'm not sure"
    }

    enum SolidFoodStatus {
        static let notYet           = "Not yet — still milk only"
        static let justStarting     = "Just starting to explore"
        static let regularly        = "Eating solids regularly"
        static let mostly           = "Mostly solids now"
    }

    enum PediatricianVisitFrequency {
        static let whenSick         = "Mostly when something feels off"
        static let everyFewMonths   = "Every few months"
        static let monthly          = "About once a month"
        static let frequently       = "More often than monthly"
    }

    enum FeedingFrequency {
        static let every2Hours      = "About every 2 hours"
        static let every3Hours      = "About every 3 hours"
        static let every4Hours      = "About every 4 hours"
        static let onDemand         = "On demand"
        static let varies           = "It varies day to day"
    }

    enum ChildcareChallenge {
        static let feeding          = "Feeding"
        static let sleeping         = "Sleeping"
        static let diapering        = "Diaper changes"
        static let soothing         = "Soothing"
        static let selfCare         = "Taking care of myself"
        static let allOfIt          = "Honestly, all of it"
    }

    enum BathingFrequency {
        static let daily            = "Every day"
        static let everyFewDays     = "Every few days"
        static let weekly           = "About once a week"
        static let asNeeded         = "Whenever it's needed"
    }

    enum AIUsageHistory {
        static let regularly        = "Yes, regularly"
        static let occasionally     = "Occasionally"
        static let onceOrTwice      = "Just once or twice"
        static let never            = "Not yet"
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
            static func escalation1Title(_ babyName: String) -> String {
                "\(babyName) is overdue for a feed"
            }
            static let escalation1Body = "Well past the usual feeding window — please check in."
            static func escalation2Title(_ babyName: String) -> String {
                "Please check on \(babyName)"
            }
            static let escalation2Body = "It's been a long stretch — log a feed when you can."
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
            static func escalation1Title(_ babyName: String) -> String {
                "\(babyName) is overtired"
            }
            static let escalation1Body = "Past the awake-window limit — try winding down now."
            static func escalation2Title(_ babyName: String) -> String {
                "\(babyName) really needs to sleep"
            }
            static let escalation2Body = "Long past the awake limit — overtired babies fight sleep harder."
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
            static func escalation1Title(_ babyName: String) -> String {
                "\(babyName)'s diaper is overdue"
            }
            static let escalation1Body = "Well past the usual change window — please check in."
            static func escalation2Title(_ babyName: String) -> String {
                "Please check \(babyName)'s diaper"
            }
            static let escalation2Body = "It's been a long stretch — a check is overdue."
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
            static let loadFailed           = "Couldn't load subscription options. Check your connection and try again."
        }

        enum Onboarding {
            static let saveFailed       = "Could not save baby profile. Please try again."
        }
    }
}
