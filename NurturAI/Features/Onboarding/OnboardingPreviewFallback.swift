import Foundation

/// Pure-local generator that produces an `OnboardingPreview` from the draft
/// without any network call. Used when the user is offline (decided up front
/// by `NetworkChecker`) or when the live AI call fails mid-onboarding, so the
/// preview screen still feels personal and earned.
///
/// Selection layering: one age-stage focus is always included; then the most
/// pressing parent-state focus (struggling > overwhelmed > solo > first-time)
/// if any; then a specific situation focus (teething > solids > top stated
/// challenge). Empty slots backfill with a secondary age-stage tip.
enum OnboardingPreviewFallback {

    static func make(draft: OnboardingViewModel.OnboardingDraft) -> OnboardingPreview {
        let name = displayName(for: draft)
        let ageInWeeks = max(
            0,
            Calendar.current.dateComponents([.weekOfYear], from: draft.birthDate, to: .now).weekOfYear ?? 0
        )

        return OnboardingPreview(
            greeting: greeting(name: name, draft: draft),
            focuses: pickFocuses(name: name, ageInWeeks: ageInWeeks, draft: draft),
            reassurance: reassurance(name: name, draft: draft)
        )
    }

    // MARK: - Greeting

    private static func greeting(name: String, draft: OnboardingViewModel.OnboardingDraft) -> String {
        if draft.emotionalWellbeing == .struggling {
            return "We're so glad you found us — and we're so glad you told us. You don't have to be okay all the time. \(name) doesn't need you to be perfect, just present. You're here, so you already are."
        }
        if draft.kidCount == .onlyChild
            && (draft.overwhelmLevel == .often || draft.overwhelmLevel == .almostAlways) {
            return "Welcome. A brand-new \(name) and brand-new feelings can feel huge. That's normal, and we're here to help you find the small steps that work."
        }
        if draft.householdType == .singleParent {
            return "We're glad you found a quiet corner here. Caring for \(name) on your own takes real strength, and we'll do what we can to make it lighter."
        }
        if draft.kidCount == .onlyChild {
            return "Welcome. Stepping into parenthood for the first time with \(name) is a big thing — and you're already showing up. That's the most important part."
        }
        return "Welcome — we're so glad you're here. Here are three small things that might help with \(name) right now."
    }

    // MARK: - Focuses

    private static func pickFocuses(
        name: String,
        ageInWeeks: Int,
        draft: OnboardingViewModel.OnboardingDraft
    ) -> [PreviewFocus] {
        var picks: [PreviewFocus] = []

        picks.append(primaryAgeFocus(name: name, ageInWeeks: ageInWeeks))

        if let stateFocus = parentStateFocus(name: name, draft: draft) {
            picks.append(stateFocus)
        }

        if let situationFocus = situationFocus(name: name, draft: draft) {
            picks.append(situationFocus)
        }

        while picks.count < 3 {
            if let extra = secondaryAgeFocus(name: name, ageInWeeks: ageInWeeks, alreadyUsed: picks) {
                picks.append(extra)
            } else {
                picks.append(PreviewFocus(
                    title: "Trust the small wins",
                    detail: "A clean diaper, a fed belly, a calm minute — those are the milestones that matter today."
                ))
            }
        }

        return Array(picks.prefix(3))
    }

    private static func primaryAgeFocus(name: String, ageInWeeks: Int) -> PreviewFocus {
        switch ageInWeeks {
        case 0..<4:
            return PreviewFocus(
                title: "Sleep in stretches, not nights",
                detail: "Newborns sleep 14–17 hours a day in 2–4 hour bursts. Match \(name)'s rhythm where you can — even brief rests count toward your reserves."
            )
        case 4..<12:
            return PreviewFocus(
                title: "Watch the wake windows",
                detail: "At this age \(name) usually does best with 60–90 minutes of awake time before needing a reset. Overtired babies fight sleep harder."
            )
        case 12..<26:
            return PreviewFocus(
                title: "Hands, rolls, and reach",
                detail: "\(name) is discovering their hands and starting to roll. Tummy time on a soft mat builds the strength they need next."
            )
        case 26..<52:
            return PreviewFocus(
                title: "Big motor moments",
                detail: "\(name) is in the crawling-to-cruising stretch. Low cabinet locks and outlet covers earn their keep right now."
            )
        default:
            return PreviewFocus(
                title: "Words and big feelings",
                detail: "\(name)'s vocabulary is exploding and so are their emotions. Naming what they feel — \"that's frustrating, isn't it?\" — helps more than fixing it."
            )
        }
    }

    private static func secondaryAgeFocus(
        name: String,
        ageInWeeks: Int,
        alreadyUsed: [PreviewFocus]
    ) -> PreviewFocus? {
        let used = Set(alreadyUsed.map(\.title))
        let secondary: PreviewFocus
        switch ageInWeeks {
        case 0..<4:
            secondary = PreviewFocus(
                title: "Skin-to-skin, often",
                detail: "Even ten minutes of chest-to-chest contact regulates breathing, temperature, and bonding. No rules — just closeness."
            )
        case 4..<12:
            secondary = PreviewFocus(
                title: "First social smiles",
                detail: "Around 6–8 weeks, \(name) starts smiling on purpose. Smile back — you're literally building their social brain."
            )
        case 12..<26:
            secondary = PreviewFocus(
                title: "Teething whispers",
                detail: "Drool, fists in mouth, and chewy fussiness can show up well before any tooth appears. A cool (not frozen) teether helps."
            )
        case 26..<52:
            secondary = PreviewFocus(
                title: "First foods, no pressure",
                detail: "Single ingredients, watch for reactions, expect mess. The first weeks of solids are about exploration, not nutrition."
            )
        default:
            secondary = PreviewFocus(
                title: "Routines as anchors",
                detail: "Predictable bedtimes, meals, and goodbyes help \(name) feel safe. The boring repetition is the magic."
            )
        }
        return used.contains(secondary.title) ? nil : secondary
    }

    private static func parentStateFocus(
        name: String,
        draft: OnboardingViewModel.OnboardingDraft
    ) -> PreviewFocus? {
        if draft.emotionalWellbeing == .struggling {
            return PreviewFocus(
                title: "You don't have to do this alone",
                detail: "Please consider talking with someone — a partner, a trusted friend, or your doctor. \(name) is so loved by you. You deserve support too."
            )
        }
        if draft.overwhelmLevel == .often || draft.overwhelmLevel == .almostAlways {
            return PreviewFocus(
                title: "A 5-minute reset, just for you",
                detail: "Drink water. Step outside. Hand \(name) off if you can. Five minutes of nothing isn't selfish — it's how you keep showing up."
            )
        }
        if draft.householdType == .singleParent || draft.familySupport == .noSupport {
            return PreviewFocus(
                title: "One micro-rest a day",
                detail: "When \(name) naps, even ten quiet minutes — a hot drink, a stretch, a podcast — protects your reserves more than another chore."
            )
        }
        if draft.kidCount == .onlyChild {
            return PreviewFocus(
                title: "Trust your instincts",
                detail: "You know \(name) better than any book or stranger online ever will. The 'right' way is the one that works for both of you."
            )
        }
        return nil
    }

    private static func situationFocus(
        name: String,
        draft: OnboardingViewModel.OnboardingDraft
    ) -> PreviewFocus? {
        if draft.teethingStatus == .teething {
            return PreviewFocus(
                title: "Cold helps when teeth hurt",
                detail: "A chilled (not frozen) teether or a damp washcloth from the fridge can soothe \(name)'s sore gums. Slow gum-rubbing with a clean finger works too."
            )
        }
        if draft.solidFoodStatus == .justStarting {
            return PreviewFocus(
                title: "Texture before taste",
                detail: "Let \(name) squish, smear, and explore new foods before swallowing matters. The mess is the lesson."
            )
        }
        if draft.solidFoodStatus == .regularly || draft.solidFoodStatus == .mostly {
            return PreviewFocus(
                title: "Variety, not volume",
                detail: "Exposure to different flavors and textures matters more than how much \(name) eats at any one meal."
            )
        }
        if let challenge = draft.childcareChallenges.first {
            return challengeFocus(name: name, challenge: challenge)
        }
        return nil
    }

    private static func challengeFocus(name: String, challenge: ChildcareChallenge) -> PreviewFocus {
        switch challenge {
        case .feeding:
            return PreviewFocus(
                title: "Feed, don't fight",
                detail: "\(name)'s appetite varies day to day. Watch their cues, not the clock — full and content beats finished bottle every time."
            )
        case .sleeping:
            return PreviewFocus(
                title: "Sleep is a 24-hour total",
                detail: "Focus on \(name)'s whole-day sleep rather than the night-by-night. Patterns shift slowly, then all at once."
            )
        case .diapering:
            return PreviewFocus(
                title: "Make changes a connection",
                detail: "A song, peek-a-boo, or steady eye contact turns the dozenth diaper change into a moment with \(name)."
            )
        case .soothing:
            return PreviewFocus(
                title: "Layer your soothing",
                detail: "Sometimes it's the third or fourth thing you try that works. Cycle gently — soft, sway, sound — and hand off if you can."
            )
        case .selfCare:
            return PreviewFocus(
                title: "Two minutes counts",
                detail: "You don't need a spa day. A stretch, a sip of something warm, or a minute by a window before \(name) wakes is real care."
            )
        case .allOfIt:
            return PreviewFocus(
                title: "Pick one thing today",
                detail: "When everything feels hard, narrow down. One feed, one nap, one diaper at a time. \(name) doesn't need it all figured out — just the next minute."
            )
        }
    }

    // MARK: - Reassurance

    private static func reassurance(name: String, draft: OnboardingViewModel.OnboardingDraft) -> String {
        if draft.emotionalWellbeing == .struggling {
            return "Please be gentle with yourself. \(name) is so loved, and so are you. We'll be here whenever you need a quiet voice."
        }
        if draft.householdType == .singleParent || draft.familySupport == .noSupport {
            return "You're carrying so much, and you're doing it. \(name) is lucky to have someone like you in their corner."
        }
        return "You're doing better than you think. \(name) is lucky to have a parent who showed up here, today, ready to learn. We've got you."
    }

    // MARK: - Helpers

    private static func displayName(for draft: OnboardingViewModel.OnboardingDraft) -> String {
        let trimmed = draft.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your little one" : trimmed
    }
}
