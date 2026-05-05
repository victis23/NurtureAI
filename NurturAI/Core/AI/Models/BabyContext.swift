import Foundation

struct BabyContext: Codable {
    // Baby profile
    let babyName: String
    let ageInWeeks: Int
    let feedingMethod: String
    let birthWeightLbs: Double
    let currentWeightLbs: Double
    let sensitivities: [String]
    let developmentalStage: String

    // Parent context
    let isFirstChild: Bool
    let familySupport: FamilySupport
    let overwhelmLevel: OverwhelmLevel
    let emotionalWellbeing: EmotionalWellbeing
    let householdType: HouseholdType
    let pediatricianVisitFrequency: PediatricianVisitFrequency
    let childcareChallenges: [ChildcareChallenge]

    // Baby additions
    let teethingStatus: TeethingStatus
    let solidFoodStatus: SolidFoodStatus
    let typicalFeedingFrequency: FeedingFrequency
    let bathingFrequency: BathingFrequency

    // Last 24h activity
    let lastFeedMinutesAgo: Int?
    let lastFeedDurationMinutes: Int?
    let lastFeedSide: String?
    let feedingsToday: Int
    let avgFeedIntervalMinutes: Int
    let lastSleepMinutesAgo: Int?
    let lastSleepDurationMinutes: Int?
    let totalSleepTodayHours: Double
    let currentAwakeWindowMinutes: Int
    let ageAppropriateMaxAwakeMinutes: Int
    let lastDiaperMinutesAgo: Int?
    let lastDiaperType: String?

    // 7-day patterns
    let sevenDayAvgLongestSleepMinutes: Int
    let sleepTrend: String

    func buildSystemPrompt(historicalContext: String? = nil) -> String {
        let sensitivitiesText = sensitivities.isEmpty ? "none reported" : sensitivities.joined(separator: ", ")
        let lastFeedText    = lastFeedMinutesAgo.map { "\($0)" } ?? "unknown"
        let lastFeedDurText = lastFeedDurationMinutes.map { "\($0)" } ?? "unknown"
        let lastFeedSideText = lastFeedSide ?? ""
        let lastSleepText   = lastSleepMinutesAgo.map { "\($0)" } ?? "unknown"
        let lastSleepDurText = lastSleepDurationMinutes.map { "\($0)" } ?? "unknown"
        let lastDiaperText  = lastDiaperMinutesAgo.map { "\($0)" } ?? "unknown"
        let lastDiaperTypeText = lastDiaperType ?? "unknown"
        let priorContextText = (historicalContext?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "none yet — this is the first turn of the conversation"

        return """
You are NurturAI, a warm and knowledgeable baby care assistant.
You help parents make confident decisions. You are NOT a doctor or medical professional.
Always present possibilities ranked by probability — never state a diagnosis.
Always include a clear escalation threshold at the end of every response.
Use encouraging, calm language. The parent is likely tired and anxious.

BABY PROFILE:
Name: \(babyName)
Age: \(ageInWeeks) weeks (\(developmentalStage))
Feeding method: \(feedingMethod) | Typical rhythm: \(feedingRhythmLabel)
Birth weight: \(String(format: "%.1f", birthWeightLbs)) lbs | Current weight: \(String(format: "%.1f", currentWeightLbs)) lbs
Known sensitivities: \(sensitivitiesText)
Teething: \(teethingLabel)
Solid foods: \(solidsLabel)
Bathing: \(bathingLabel)

PARENT CONTEXT:
\(parentContextLines().joined(separator: "\n"))

LAST 24 HOURS:
Last feeding: \(lastFeedText) minutes ago, duration \(lastFeedDurText) min, \(lastFeedSideText)
Feedings today: \(feedingsToday) (avg every \(avgFeedIntervalMinutes) min)
Last sleep: \(lastSleepText) min ago, duration \(lastSleepDurText) min
Total sleep today: \(String(format: "%.1f", totalSleepTodayHours)) hours
Current awake window: \(currentAwakeWindowMinutes) min (age-appropriate max: \(ageAppropriateMaxAwakeMinutes) min)
Last diaper: \(lastDiaperText) min ago (\(lastDiaperTypeText))

7-DAY PATTERNS:
Avg longest sleep stretch: \(sevenDayAvgLongestSleepMinutes) min
Sleep trend: \(sleepTrend)

PRIOR CONVERSATION CONTEXT (rolling summary from earlier turns in THIS conversation, may be empty):
\(priorContextText)

CRITICAL RULES:
1. Never use "you have", "this is a diagnosis of", or "diagnosed with".
   Use "this could be", "one possibility is", "this looks like".
2. If confidence is below 40, include a note that you are less certain.
3. Populate the `escalation` block ONLY when clinically warranted. The default for every array is empty.
   - `er`: ONLY for true emergencies — difficulty breathing, bluish/grey skin or lips, fever in a baby under 3 months, seizure-like activity, unresponsiveness, severe dehydration, head injury with vomiting, suspected airway obstruction. Empty otherwise.
   - `call_doctor`: ONLY when there's a genuine concern warranting a same-day or next-day call — high fever, persistent symptoms beyond a typical course, feeding refusal lasting hours, blood in stool, atypical behavior the parent has explicitly noticed. Empty otherwise.
   - `monitor`: Mild watch-for items. The most permissive of the three, but every item MUST relate specifically to this question — no generic boilerplate.
   For routine baby-care questions (feeding rhythm, sleep windows, wake-window optimization, normal development, soothing techniques, growth curiosities, mild fussiness without warning signs), `er` AND `call_doctor` MUST both be empty arrays `[]`. Do NOT add safe-default phrases like "call your doctor if it persists" — include items only when they are genuinely clinically significant for the specific question being asked. When in doubt, leave the array empty; the user can always ask a follow-up.
4. Ground every cause in the baby's specific context above.
5. Maximum 3 causes. Rank by probability descending.
5a. ALL percentage fields (`probability`, `confidence`) MUST be integers on a 0–100 scale (e.g. `65` for 65%, `0` for 0%, `100` for 100%). NEVER use 0–1 decimals like `0.65`. This is mandatory — the UI relies on it.
6. Calibrate tone to the parent context above. If the parent has shared they've been struggling emotionally or frequently overwhelmed, lead with brief validation before advising. If they're parenting solo or without nearby support, never assume a partner is available to help.
7. If the question is NOT about baby or infant care (feeding, sleep, diapers, development, health, growth, behavior), respond with this exact JSON and nothing else:
   {"causes":[],"escalation":{"er":[],"call_doctor":[],"monitor":[]},"reassurance":"I can only help with questions about \(babyName)'s care — things like feeding, sleep, diapers, development, or health. What's going on with \(babyName) today?","confidence":0,"follow_up":null,"historical_context":null}
8. If PRIOR CONVERSATION CONTEXT above is non-empty, treat the new question as a follow-up — reference what was already shared rather than asking for it again, and resolve pronouns/short references against it.
9. Always populate `historical_context` with a 1–3 sentence rolling summary that future turns can use to feel continuous. Carry forward any still-relevant facts from the prior context, refine or replace anything contradicted by the new turn, and add any new details the parent shared that should inform later answers (symptoms noticed, recent events, parent's worries, what's already been tried). Keep it factual and parent-focused — not a recap of your own advice. If nothing new is worth remembering, return the prior context unchanged.

Respond ONLY with valid JSON in this exact schema — no markdown, no preamble:
{
  "causes": [
    {
      "label": string,
      "probability": integer (0-100, e.g. 65 — NEVER 0.65),
      "reasoning": string,
      "actions": [string]
    }
  ],
  "escalation": {
    "er": [string],
    "call_doctor": [string],
    "monitor": [string]
  },
  "reassurance": string,
  "confidence": integer (0-100, e.g. 75 — NEVER 0.75),
  "follow_up": string,
  "historical_context": string
}
"""
    }

    private func parentContextLines() -> [String] {
        var lines: [String] = []

        lines.append(isFirstChild
            ? "First-time parent — clear explanations and reassurance are especially helpful."
            : "Experienced parent — assume baseline parenting knowledge.")

        switch familySupport {
        case .strong:           lines.append("Has a strong support system at home.")
        case .occasional:       lines.append("Has occasional support — often parenting solo.")
        case .noSupport:        lines.append("Mostly parenting without nearby support — be especially gentle.")
        case .preferNotToSay:   break
        }

        switch emotionalWellbeing {
        case .someHardDays:     lines.append("Parent has shared they have hard days — be extra warm and patient.")
        case .struggling:       lines.append("Parent has indicated they've been struggling emotionally. Lead with warmth and validation; if their question hints at distress beyond infant care, gently acknowledge their feelings.")
        case .doingOkay, .preferNotToSay: break
        }

        switch overwhelmLevel {
        case .sometimes:        lines.append("Sometimes feels overwhelmed.")
        case .often:            lines.append("Often feels overwhelmed — prioritize calm, manageable steps.")
        case .almostAlways:     lines.append("Almost always feels overwhelmed — prioritize the smallest possible next step over volume of advice.")
        case .rarely, .preferNotToSay: break
        }

        switch householdType {
        case .twoParent:        lines.append("Two-parent household.")
        case .singleParent:     lines.append("Solo parent — do not assume a partner is available to help.")
        case .coParenting:      lines.append("Co-parents across two households.")
        case .extendedFamily:   lines.append("Lives with extended family who help with care.")
        case .other, .preferNotToSay: break
        }

        lines.append("Pediatrician visits: \(pediatricianFreqLabel).")

        if !childcareChallenges.isEmpty {
            let names = childcareChallenges.map { $0.displayName.lowercased() }.joined(separator: ", ")
            lines.append("Self-reported hardest aspects: \(names).")
        }

        return lines
    }

    private var pediatricianFreqLabel: String {
        switch pediatricianVisitFrequency {
        case .whenSick:         return "mostly when something feels off"
        case .everyFewMonths:   return "every few months"
        case .monthly:          return "monthly"
        case .frequently:       return "more than monthly"
        }
    }

    private var teethingLabel: String {
        switch teethingStatus {
        case .teething:         return "actively teething"
        case .notYet:           return "not yet"
        case .unsure:           return "unclear"
        }
    }

    private var solidsLabel: String {
        switch solidFoodStatus {
        case .notYet:           return "exclusively milk"
        case .justStarting:     return "just starting solids"
        case .regularly:        return "regularly eating solids"
        case .mostly:           return "mostly on solids"
        }
    }

    private var feedingRhythmLabel: String {
        switch typicalFeedingFrequency {
        case .every2Hours:      return "about every 2 hours"
        case .every3Hours:      return "about every 3 hours"
        case .every4Hours:      return "about every 4 hours"
        case .onDemand:         return "on demand"
        case .varies:           return "varies day to day"
        }
    }

    private var bathingLabel: String {
        switch bathingFrequency {
        case .daily:            return "daily"
        case .everyFewDays:     return "every few days"
        case .weekly:           return "about weekly"
        case .asNeeded:         return "as needed"
        }
    }

    static func developmentalStage(ageInWeeks: Int) -> String {
        switch ageInWeeks {
        case 0..<4:   return "Newborn"
        case 4..<12:  return "Early Infant"
        case 12..<26: return "Infant"
        case 26..<52: return "Older Infant"
        default:      return "Toddler"
        }
    }
}
