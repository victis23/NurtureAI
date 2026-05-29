import Foundation

// MARK: - Strings
// Single source of truth for all user-facing text in NurturAI.
//
// Usage:  Text(Strings.Home.title)
//         TextField(Strings.Assist.inputPlaceholder, text: $query)
//
// Localization: every value is wrapped in `String(localized:)` so Xcode can
// extract them into a Localizable.xcstrings catalog. Interpolated values become
// format arguments automatically.

enum Strings {

    // MARK: - Common
    enum Common {
        static let appName          = String(localized: "NurturAI")
        static let cancel           = String(localized: "Cancel")
        static let save             = String(localized: "Save")
        static let edit             = String(localized: "Edit")
        static let ok               = String(localized: "OK")
        static let back             = String(localized: "Back")
        static let close            = String(localized: "Close")
        static let logNow           = String(localized: "Log Now")
        static let somethingWrong   = String(localized: "Something went wrong")
        static let unknownError     = String(localized: "An unknown error occurred.")
        static let noBabyProfile    = String(localized: "No baby profile")
        static let stop             = String(localized: "Stop")
        static let done             = String(localized: "Done")
        static let yes              = String(localized: "Yes")
        static let no               = String(localized: "No")
        static let notShared        = String(localized: "Not shared")
        static let noneSelected     = String(localized: "None selected")
        static let tapToSet         = String(localized: "Tap to set")
        static let unitPounds       = String(localized: "lb")
        static let unitOunces       = String(localized: "oz")
        static let termsTitle       = String(localized: "Terms of Use")
        static let privacyTitle     = String(localized: "Privacy Policy")
        static let viewPrivacyPolicy = String(localized: "View Privacy Policy")
        static let contactHeading   = String(localized: "Contact")
    }

    // MARK: - Tab Bar
    enum TabBar {
        static let today    = String(localized: "Today")
        static let askAI    = String(localized: "Ask AI")
        static let log      = String(localized: "Log")
        static let history  = String(localized: "History")
        static let settings = String(localized: "Settings")
    }

    // MARK: - Auth
    enum Auth {
        static let tagline          = String(localized: "Confident parenting,\none moment at a time.")
        static let legalDisclaimer  = String(localized: "By continuing, you agree to our Terms of Service and Privacy Policy.")
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let navigationTitle  = String(localized: "Welcome to NurturAI")
        static let continueButton   = String(localized: "Continue")
        static let getStarted       = String(localized: "Get Started")
        static let useFreeTrial     = String(localized: "Start 3-Day Free Trial")
        static let tryForFree       = String(localized: "Try For Free")

        enum Greeting {
            static let welcome = String(localized: "Welcome to Nurtur")
            static let welcomeSubTitle = String(localized: "Your ai parenting helper")

            static let greeting1 = String(localized: "We know parenting can feel overwhelming—especially when it’s all new. That’s exactly why we created this app.")

            static let greeting2 = String(localized: "Our goal is simple: to support you with guidance you can trust, so you can focus on what matters most—your baby.")
            static let greeting3 = String(localized: "Get instant, personalized answers tailored to your child, powered by AI and grounded in real pediatric research. Because you deserve confidence, not guesswork.")
        }

        enum Name {
            static let heading      = String(localized: "What's your baby's name?")
            static let subheading   = String(localized: "You can always change this later.")
            static let placeholder  = String(localized: "Baby's name")
        }

        enum Birthday {
            static let heading      = String(localized: "When was your baby born?")
            static let subheading   = String(localized: "We use this to personalise advice for their age and stage.")
            static let pickerLabel  = String(localized: "Date of birth")
            static let dueSoon      = String(localized: "due soon")
            static let bornToday    = String(localized: "born today")
            static func daysOld(_ days: Int) -> String { String(localized: "\(days) day\(days == 1 ? "" : "s") old") }
            static func weeksOld(_ weeks: Int) -> String { String(localized: "\(weeks) week\(weeks == 1 ? "" : "s") old") }
            static func monthsOld(_ months: Int) -> String { String(localized: "\(months) month\(months == 1 ? "" : "s") old") }
            static func yearsOld(_ years: Int) -> String { String(localized: "\(years) year\(years == 1 ? "" : "s") old") }
        }

        enum Feeding {
            static let heading      = String(localized: "How are you feeding?")
            static let subheading   = String(localized: "NurturAI tailors feed tracking and AI responses to your method.")
        }

        enum KidCount {
            static let heading      = String(localized: "Is this your first child?")
            static let subheading   = String(localized: "NurturAI tailors tracking and AI responses to your experience level, stress indicators, and other data points.")
            static let dataProtectionStatement = String(localized: "Remember your data will always be protected and confidential.")
        }

        enum Support {
            static let heading      = String(localized: "Do you have someone you can lean on?")
            static let subheading   = String(localized: "Parenting feels lighter when there's a hand to hold. We'd love to know who's in your corner.")
        }

        enum Overwhelm {
            static let heading      = String(localized: "Have things felt like a lot lately?")
            static let subheading   = String(localized: "It's okay if they have. Even the gentlest days of parenthood can feel like a lot — there's no judgement here.")
        }

        enum Wellbeing {
            static let heading      = String(localized: "How has your heart been feeling?")
            static let subheading   = String(localized: "Becoming a parent can stir up emotions that are hard to name. Whatever you share stays private — we'll always meet you with care.")
        }

        enum Household {
            static let heading      = String(localized: "Who's part of your parenting team at home?")
            static let subheading   = String(localized: "Every family looks different, and we want to support yours just as it is.")
        }

        enum Features {
            static let heading      = String(localized: "What would feel most helpful right now?")
            static let subheading   = String(localized: "Pick anything that catches your eye — we'll personalize the app to you.")
            static let multiSelectHint = String(localized: "Select all that apply.")
        }

        enum InternetUsage {
            static let heading      = String(localized: "How often do you turn to the internet for answers about your little one?")
            static let subheading   = String(localized: "We've all done it. Knowing this helps us bring trustworthy info closer to you, so you don't have to dig.")
        }

        enum AppDiscovery {
            static let heading      = String(localized: "How did you find your way to us?")
            static let subheading   = String(localized: "We're so glad you're here.")
        }

        enum Teething {
            static let heading      = String(localized: "Has teething started yet?")
            static let subheading   = String(localized: "Those first little teeth bring big feelings — for everyone.")
        }

        enum SolidFoods {
            static let heading      = String(localized: "Has your little one started exploring solid foods?")
            static let subheading   = String(localized: "Every tiny taste is a milestone. We'll meet you wherever you are.")
        }

        enum Pediatrician {
            static let heading      = String(localized: "How often do you visit the pediatrician?")
            static let subheading   = String(localized: "We'll tailor reminders and tips to fit your rhythm.")
        }

        enum BirthWeight {
            static let heading      = String(localized: "How much did your little one weigh at birth?")
            static let subheading   = String(localized: "We use this to gently track growth over time.")
            static let placeholder  = String(localized: "Birth weight")
        }

        enum CurrentWeight {
            static let heading      = String(localized: "And what was their weight at the last check?")
            static let subheading   = String(localized: "Their latest weigh-in helps us spot growth patterns. You can update it any time later.")
            static let placeholder  = String(localized: "Current weight")
        }

        enum Weight {
            static let poundsPicker = String(localized: "Pounds")
            static let ouncesPicker = String(localized: "Ounces")
            static func gramsApprox(_ grams: Int) -> String { String(localized: "≈ \(grams) g") }
            static func pounds(_ value: Int) -> String { String(localized: "\(value) lb") }
            static func ounces(_ value: Int) -> String { String(localized: "\(value) oz") }
        }

        enum FeedingFreq {
            static let heading      = String(localized: "How often does your little one feed in a typical day?")
            static let subheading   = String(localized: "Every baby has their own rhythm — there's no wrong answer.")
        }

        enum Challenges {
            static let heading      = String(localized: "What's been feeling the hardest right now?")
            static let subheading   = String(localized: "We all have those moments. Knowing this helps us focus where you need us most.")
            static let multiSelectHint = String(localized: "Select all that apply.")
        }

        enum Bathing {
            static let heading      = String(localized: "How often does bath time happen at your house?")
            static let subheading   = String(localized: "Splashy and daily or weekly and calm — both are perfect.")
        }

        enum AIUsage {
            static let heading      = String(localized: "Have you used AI for parenting support before?")
            static let subheading   = String(localized: "There's no right or wrong answer — we'll meet you wherever you are.")
        }

        enum AIPreview {
            static let heading          = String(localized: "A first taste, just for you")
            static let subheading       = String(localized: "Based on what you shared, here's a personalized first insight from NurturAI.")
            static let loadingTitle     = String(localized: "Personalizing your first insight…")
            static let loadingSubtitle  = String(localized: "Drawing from what you shared about your little one.")
        }

        enum Rating {
            static let heading          = String(localized: "Help other parents find us")
            static let subheading       = String(localized: "If NurturAI is starting to feel like a helpful corner for you, a quick rating means the world.")
            static let encourageTitle   = String(localized: "Why your rating matters")
            static let encourageBody    = String(localized: "Real reviews from parents like you help tired families find help when they need it most. It takes about 10 seconds — and every star genuinely counts.")
            static let actionLabel      = String(localized: "Leave a rating")
            static let skipLabel        = String(localized: "Maybe later")
        }
    }

    // MARK: - Home
    enum Home {
        static let navigationTitle  = String(localized: "Today")
        static let notLogged        = String(localized: "Not logged")
        static let feedingsToday    = String(localized: "feedings today")
        static let askAI            = String(localized: "Ask AI")
        static let feed             = String(localized: "Feed")
        static let sleep            = String(localized: "Sleep")
        static let diaper           = String(localized: "Diaper")
        static let atAGlance        = String(localized: "At a glance")
        static let quickLog         = String(localized: "Quick log")
        static let timeline         = String(localized: "Today's timeline")

        enum Status {
            static let lastFed           = String(localized: "Last Fed")
            static let awake             = String(localized: "Awake")
            static let sleepToday        = String(localized: "Sleep Today")
            static let lastDiaper        = String(localized: "Last Diaper")
            static let currentlyFeeding  = String(localized: "Currently feeding")
            static let currentlySleeping = String(localized: "Currently sleeping")
            static func maxAwake(_ value: String) -> String { String(localized: "Max \(value)m recommended") }
        }

        enum Timer {
            static let feedInProgress   = String(localized: "Feeding in progress")
            static let sleepInProgress  = String(localized: "Sleep in progress")
            static let diaperInProgress = String(localized: "Diaper is being changed")
            static let moodLogged       = String(localized: "Mood logged")
        }

        enum Prediction {
            static let title        = String(localized: "Getting tired?")
        }

        enum TimelineEvent {
            static let feed         = String(localized: "Feed")
            static let sleep        = String(localized: "Sleep")
            static let diaperChange = String(localized: "Diaper change")
            static let mood         = String(localized: "Mood")
        }

        enum EmptyTimeline {
            static let title    = String(localized: "A fresh day")
            static let message  = String(localized: "Nothing logged yet. Tap a quick-log button above and the timeline will fill in here.")
        }
    }

    // MARK: - Log
    enum Log {
        static let navigationTitle  = String(localized: "Log")
        static let headerPrompt     = String(localized: "What would you like to log?")
        static let pickerLabel      = String(localized: "Log type")
        static let tabFeed          = String(localized: "Feed")
        static let tabSleep         = String(localized: "Sleep")
        static let tabDiaper        = String(localized: "Diaper")
        static let tabMood          = String(localized: "Mood")
        static func savedConfirmation(_ type: String) -> String { String(localized: "Logged \(type) ✓") }
        static func moodHeading(_ name: String) -> String { String(localized: "How is \(name) feeling?") }

        enum Feed {
            static let sideLabel        = String(localized: "Side")
            static let amountLabel      = String(localized: "Amount (ml)")
            static let inProgress       = String(localized: "Feeding in progress")
            static let readyToStart     = String(localized: "Ready to start")
            static let stopFeed         = String(localized: "Stop Feed")
            static let startFeed        = String(localized: "Start Feed")
        }

        enum Sleep {
            static let inProgress       = String(localized: "Sleep in progress")
            static let readyToStart     = String(localized: "Ready to start")
            static let wakeUp           = String(localized: "Wake Up")
            static let startSleep       = String(localized: "Start Sleep")
        }

        enum Diaper {
            static let typeLabel        = String(localized: "Diaper type")
        }
    }

    // MARK: - History
    enum History {
        static let navigationTitle  = String(localized: "History")
        static let noLogsTitle      = String(localized: "No logs yet")
        static let noLogsMessage    = String(localized: "Start logging feeds, sleep, and diapers.")
        static let today            = String(localized: "Today")
        static let yesterday        = String(localized: "Yesterday")
        static let editStartLabel   = String(localized: "Start")
        static let editEndLabel     = String(localized: "End")
        static func editTitle(_ type: String) -> String { String(localized: "Edit \(type)") }
    }

    // MARK: - Assist
    enum Assist {
        static let navigationTitle      = String(localized: "Ask NurturAI")
        static let freeLeft             = String(localized: "free left")
        static let loadingMessage       = String(localized: "Looking into this…")
        static let askAnother           = String(localized: "Ask another question")
        static let inputPlaceholder     = String(localized: "Describe what's happening right now...")
        static let errorFallback        = String(localized: "An error occurred.")
        static let doctorEscalation     = String(localized: "This question may relate to a condition worth discussing with your pediatrician.")

        enum Response {
            static let lowConfidenceNote    = String(localized: "Lower confidence — there may be less information available for this situation.")
            static let monitorHeading       = String(localized: "Keep an eye on:")
        }

        enum QuickPicks {
            static let crying       = String(localized: "Crying")
            static let wontSleep    = String(localized: "Won't sleep")
            static let feedingIssue = String(localized: "Feeding issue")
            static let rash         = String(localized: "Rash")
            static let fever        = String(localized: "Fever")
            static let gasFussiness = String(localized: "Gas/Fussiness")
        }

        enum Escalation {
            static let emergencyHeading     = String(localized: "SEEK EMERGENCY CARE")
            static let emergencySubheading  = String(localized: "or call 911 immediately")
            static let doctorHeading        = String(localized: "Consider calling your pediatrician if:")
        }

        enum Feedback {
            static let prompt       = String(localized: "Did this help?")
            static let thanks       = String(localized: "Thanks for the feedback!")
        }
    }

    // MARK: - Settings
    enum Settings {
        static let navigationTitle      = String(localized: "Settings")

        enum BabyProfile {
            static let sectionTitle     = String(localized: "Baby Profile")
            static let nameLabel        = String(localized: "Name")
            static let birthdayLabel    = String(localized: "Birthday")
        }

        enum Edit {
            static let yourBabySection      = String(localized: "Your Baby")
            static let dailyCareSection     = String(localized: "Daily Care")
            static let familySection        = String(localized: "Family & Support")
            static let wellbeingSection     = String(localized: "How You're Feeling")
            static let appSection           = String(localized: "App Preferences")
        }

        enum Fields {
            static let name             = String(localized: "Name")
            static let birthday         = String(localized: "Birthday")
            static let firstChild       = String(localized: "First child")
            static let birthWeight      = String(localized: "Birth weight")
            static let currentWeight    = String(localized: "Current weight")
            static let teething         = String(localized: "Teething")
            static let solidFoods       = String(localized: "Solid foods")
            static let feedingMethod    = String(localized: "Feeding method")
            static let feedingRhythm    = String(localized: "Feeding rhythm")
            static let bathing          = String(localized: "Bathing")
            static let pediatricianVisits = String(localized: "Pediatrician visits")
            static let household        = String(localized: "Household")
            static let supportSystem    = String(localized: "Support system")
            static let hardestAspects   = String(localized: "Hardest aspects")
            static let howYoureFeeling  = String(localized: "How you're feeling")
            static let overwhelm        = String(localized: "Overwhelm")
            static let helpfulFeatures  = String(localized: "Helpful features")
            static let onlineResearch   = String(localized: "Online research habits")
            static let aiExperience     = String(localized: "AI experience")
            static let howYouFoundUs    = String(localized: "How you found us")

            static func weight(pounds: Int, ounces: Int) -> String { String(localized: "\(pounds) lb \(ounces) oz") }
            static func moreSummary(first: String, second: String, extra: Int) -> String { String(localized: "\(first), \(second) +\(extra) more") }
        }

        enum Subscription {
            static let sectionTitle     = String(localized: "Subscription")
            static let proPlan          = String(localized: "Pro Plan")
            static let freePlan         = String(localized: "Free Plan")
            static let proDescription   = String(localized: "Unlimited AI queries")
            static let freeDescription  = String(localized: "3 AI queries per day")
            static let upgradeToPro     = String(localized: "Upgrade to Pro")
        }

        enum Caregivers {
            static let sectionTitle         = String(localized: "Caregivers")
            static let addCaregiver         = String(localized: "Add Caregiver")
            static let pendingFeatureTitle  = String(localized: "Coming Soon!")
        }

        enum Legal {
            static let sectionTitle     = String(localized: "Legal")
            static let privacyPolicy    = String(localized: "Privacy Policy")
            static let termsOfService   = String(localized: "Terms of Service")
        }

        enum AI {
            static let sectionTitle      = String(localized: "AI")
            static let resetMemory       = String(localized: "Reset AI Memory")
            static let resetAlertTitle   = String(localized: "Reset AI Memory?")
            static let resetAlertBody    = String(localized: "This clears the current conversation and the AI's memory of past chats. Your logs, saved history, and account stay intact. Future replies will start fresh until you've had more conversations.")
            static let resetConfirm      = String(localized: "Reset")
        }

        enum Account {
            static let signOut          = String(localized: "Sign Out")
            static let deleteAccount     = String(localized: "Delete Account")
            static let sectionTitle = String(localized: "Account Management")

            // Re-auth confirmation flow (run before any destructive delete work)
            static let reauthTitle       = String(localized: "Confirm It's You")
            static let reauthMessage     = String(localized: "For your security, please sign in with Apple again. Nothing will be deleted until this succeeds.")
            static let reauthCancel      = String(localized: "Not Now")
            static let deleteAlertTitle  = String(localized: "Delete Account?")
            static let deleteAlertBody   = String(localized: "You'll be asked to sign in with Apple to confirm. This permanently deletes your account, your baby profile, and all logged data. It cannot be undone.")
            static let deleteConfirm     = String(localized: "Continue")
        }
    }

    // MARK: - Paywall
    enum Paywall {
        static let navigationTitle      = String(localized: "Upgrade")
        static let title                = String(localized: "NurturAI Pro")
        static let subtitle             = String(localized: "Unlimited AI questions, priority responses,\nand caregiver sharing.")
        static let bestValue            = String(localized: "BEST VALUE")
        static let restorePurchases     = String(localized: "Restore Purchases")
        // Apple Guideline 3.1.2(c) requires a clear auto-renew disclosure in
        // the purchase flow itself. Do not soften this — Apple's reviewers
        // look for this exact pattern of language.
        static let footer               = String(localized: "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Your Apple ID will be charged for renewal within 24 hours prior to the end of the current period. Manage or cancel anytime in Settings → Apple ID → Subscriptions.")
        static let privacyPolicy        = String(localized: "Privacy Policy")
        static let termsOfUse           = String(localized: "Terms of Use")
        static let autoRenewSuffix      = String(localized: "auto-renewing")
        static let perMonthSuffix       = String(localized: "/mo")
        static let loadingProducts      = String(localized: "Loading subscription options…")
        static let tryAgain             = String(localized: "Try again")
        static let restored             = String(localized: "Subscription restored.")
        static let noPurchasesFound     = String(localized: "No previous purchases found.")
    }

    // MARK: - Products
    enum Products {
        static let proMonthlyName       = String(localized: "Pro Monthly")
        static let proAnnualName        = String(localized: "Pro Annual")
        static let familyAnnualName     = String(localized: "Family Annual")
        static let proMonthlyPrice      = String(localized: "$14.99/mo")
        static let proAnnualPrice       = String(localized: "$99.00/yr")
        static let familyAnnualPrice    = String(localized: "$149.00/yr")
    }

    // MARK: - Enums Display
    enum FeedingMethod {
        static let breast   = String(localized: "Breastfeeding")
        static let formula  = String(localized: "Formula")
        static let combo    = String(localized: "Combo")
    }

    enum ChildCount {
        static let hasOneKid = String(localized: "Yes, this is my first kid.")
        static let hasManyKids = String(localized: "No, this isn't my first kid.")
    }

    enum FamilySupport {
        static let strong           = String(localized: "Yes, I have a strong support system")
        static let occasional       = String(localized: "Sometimes, when I really need it")
        static let noSupport        = String(localized: "It's mostly on me right now")
        static let preferNotToSay   = String(localized: "I'd rather not say")
    }

    enum OverwhelmLevel {
        static let rarely           = String(localized: "Rarely — I feel mostly steady")
        static let sometimes        = String(localized: "Sometimes, on the harder days")
        static let often            = String(localized: "Often")
        static let almostAlways     = String(localized: "Almost always")
        static let preferNotToSay   = String(localized: "I'd rather not say")
    }

    enum EmotionalWellbeing {
        static let doingOkay        = String(localized: "I'm doing okay")
        static let someHardDays     = String(localized: "I have some hard days")
        static let struggling       = String(localized: "I've been struggling")
        static let preferNotToSay   = String(localized: "I'd rather not say")
    }

    enum HouseholdType {
        static let twoParent        = String(localized: "Two parents at home")
        static let singleParent     = String(localized: "Just me, parenting solo")
        static let coParenting      = String(localized: "Co-parenting across two homes")
        static let extendedFamily   = String(localized: "With extended family")
        static let other            = String(localized: "Something else")
        static let preferNotToSay   = String(localized: "I'd rather not say")
    }

    enum DesiredFeature {
        static let sleepTracking    = String(localized: "Sleep tracking")
        static let feedingTracking  = String(localized: "Feeding tracking")
        static let aiAdvice         = String(localized: "AI guidance and answers")
        static let milestones       = String(localized: "Milestone tracking")
        static let growthTracking   = String(localized: "Growth tracking")
        static let diaperTracking   = String(localized: "Diaper tracking")
        static let communitySupport = String(localized: "Community and support")
    }

    enum InternetUsageFrequency {
        static let rarely           = String(localized: "Rarely")
        static let sometimes        = String(localized: "Sometimes")
        static let daily            = String(localized: "Most days")
        static let manyTimesDaily   = String(localized: "Many times a day")
    }

    enum AppDiscoverySource {
        static let friendOrFamily   = String(localized: "A friend or family member")
        static let appStore         = String(localized: "Browsing the App Store")
        static let socialMedia      = String(localized: "Social media")
        static let advertisement    = String(localized: "An ad")
        static let webSearch        = String(localized: "A web search")
        static let other            = String(localized: "Somewhere else")
    }

    enum TeethingStatus {
        static let teething         = String(localized: "Yes, we're in it")
        static let notYet           = String(localized: "Not yet")
        static let unsure           = String(localized: "I'm not sure")
    }

    enum SolidFoodStatus {
        static let notYet           = String(localized: "Not yet — still milk only")
        static let justStarting     = String(localized: "Just starting to explore")
        static let regularly        = String(localized: "Eating solids regularly")
        static let mostly           = String(localized: "Mostly solids now")
    }

    enum PediatricianVisitFrequency {
        static let whenSick         = String(localized: "Mostly when something feels off")
        static let everyFewMonths   = String(localized: "Every few months")
        static let monthly          = String(localized: "About once a month")
        static let frequently       = String(localized: "More often than monthly")
    }

    enum FeedingFrequency {
        static let every2Hours      = String(localized: "About every 2 hours")
        static let every3Hours      = String(localized: "About every 3 hours")
        static let every4Hours      = String(localized: "About every 4 hours")
        static let onDemand         = String(localized: "On demand")
        static let varies           = String(localized: "It varies day to day")
    }

    enum ChildcareChallenge {
        static let feeding          = String(localized: "Feeding")
        static let sleeping         = String(localized: "Sleeping")
        static let diapering        = String(localized: "Diaper changes")
        static let soothing         = String(localized: "Soothing")
        static let selfCare         = String(localized: "Taking care of myself")
        static let allOfIt          = String(localized: "Honestly, all of it")
    }

    enum BathingFrequency {
        static let daily            = String(localized: "Every day")
        static let everyFewDays     = String(localized: "Every few days")
        static let weekly           = String(localized: "About once a week")
        static let asNeeded         = String(localized: "Whenever it's needed")
    }

    enum AIUsageHistory {
        static let regularly        = String(localized: "Yes, regularly")
        static let occasionally     = String(localized: "Occasionally")
        static let onceOrTwice      = String(localized: "Just once or twice")
        static let never            = String(localized: "Not yet")
    }

    enum Mood {
        static let content  = String(localized: "Content")
        static let fussy    = String(localized: "Fussy")
        static let crying   = String(localized: "Crying")
        static let settled  = String(localized: "Settled")
        static let sleeping = String(localized: "Sleeping")
    }

    // MARK: - Notifications
    /// User-facing copy for local UNNotification reminders.
    /// All "primary" copy fires when a feed/sleep/diaper window is reached;
    /// "followup" copy fires `NotificationService.followupDelayMinutes` later if ignored.
    enum Notifications {

        enum Feed {
            static func primaryTitle(_ babyName: String) -> String {
                String(localized: "Time to feed \(babyName)")
            }
            static func primaryBody(_ minutesAgo: Int) -> String {
                String(localized: "It's been \(minutesAgo) min since the last feeding.")
            }
            static func followupTitle(_ babyName: String) -> String {
                String(localized: "\(babyName) still needs to be fed")
            }
            static let followupBody = String(localized: "It's been a while since the last feeding — don't forget to log it.")
            static func escalation1Title(_ babyName: String) -> String {
                String(localized: "\(babyName) is overdue for a feed")
            }
            static let escalation1Body = String(localized: "Well past the usual feeding window — please check in.")
            static func escalation2Title(_ babyName: String) -> String {
                String(localized: "Please check on \(babyName)")
            }
            static let escalation2Body = String(localized: "It's been a long stretch — log a feed when you can.")
        }

        enum Sleep {
            static func primaryTitle(_ babyName: String) -> String {
                String(localized: "\(babyName) may be getting tired")
            }
            static func primaryBody(_ babyName: String, awakeMinutes: Int, maxMinutes: Int) -> String {
                String(localized: "\(babyName) has been awake for \(awakeMinutes) min — approaching the \(maxMinutes) min limit.")
            }
            static func followupTitle(_ babyName: String) -> String {
                String(localized: "\(babyName) is past their awake window")
            }
            static let followupBody = String(localized: "Overtired babies struggle to fall asleep — try winding down soon.")
            static func escalation1Title(_ babyName: String) -> String {
                String(localized: "\(babyName) is overtired")
            }
            static let escalation1Body = String(localized: "Past the awake-window limit — try winding down now.")
            static func escalation2Title(_ babyName: String) -> String {
                String(localized: "\(babyName) really needs to sleep")
            }
            static let escalation2Body = String(localized: "Long past the awake limit — overtired babies fight sleep harder.")
        }

        enum Diaper {
            static func primaryTitle(_ babyName: String) -> String {
                String(localized: "Time to check \(babyName)'s diaper")
            }
            static func primaryBody(_ minutesAgo: Int) -> String {
                String(localized: "It's been \(minutesAgo) min since the last diaper change.")
            }
            static func followupTitle(_ babyName: String) -> String {
                String(localized: "\(babyName)'s diaper still needs checking")
            }
            static let followupBody = String(localized: "Don't forget to check and log a diaper change.")
            static func escalation1Title(_ babyName: String) -> String {
                String(localized: "\(babyName)'s diaper is overdue")
            }
            static let escalation1Body = String(localized: "Well past the usual change window — please check in.")
            static func escalation2Title(_ babyName: String) -> String {
                String(localized: "Please check \(babyName)'s diaper")
            }
            static let escalation2Body = String(localized: "It's been a long stretch — a check is overdue.")
        }
    }

    // MARK: - Errors
    enum Errors {
        enum App {
            static let dataError        = String(localized: "A data error occurred. Please try again.")
            static let networkError     = String(localized: "A network error occurred. Check your connection and try again.")
            static let unknownError     = String(localized: "An unexpected error occurred. Please try again.")
            static let aiRecovery       = String(localized: "Check your internet connection or try a different question.")
            static let dataRecovery     = String(localized: "Try restarting the app.")
            static let networkRecovery  = String(localized: "Check your internet connection.")
            static let unknownRecovery  = String(localized: "If the problem persists, please restart the app.")
        }

        enum AI {
            static let invalidResponse  = String(localized: "The AI service returned an unexpected response.")
            static func httpError(_ code: Int) -> String { String(localized: "The AI service returned an error (HTTP \(code)).") }
            static let parseError       = String(localized: "Could not understand the AI response. Please try again.")
            static let contextUnavailable = String(localized: "Baby context could not be loaded. Please try again.")
        }

        enum Auth {
            static let invalidCredential   = String(localized: "Sign in failed. Please try again.")
            static let notSignedIn         = String(localized: "You must be signed in to perform this action.")
            static let requiresRecentLogin = String(localized: "For your security, please sign in again before deleting your account.")
        }

        enum Subscription {
            static let productNotFound      = String(localized: "Product not found. Please try again later.")
            static let verificationFailed   = String(localized: "Purchase could not be verified.")
            static let pending              = String(localized: "Your purchase is pending approval.")
            static let unknown              = String(localized: "An unknown error occurred.")
            static let loadFailed           = String(localized: "Couldn't load subscription options. Check your connection and try again.")
        }

        enum Onboarding {
            static let saveFailed       = String(localized: "Could not save baby profile. Please try again.")
        }
    }
}
