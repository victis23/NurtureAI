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

    func buildSystemPrompt() -> String {
        let sensitivitiesText = sensitivities.isEmpty ? "none reported" : sensitivities.joined(separator: ", ")
        let lastFeedText    = lastFeedMinutesAgo.map { "\($0)" } ?? "unknown"
        let lastFeedDurText = lastFeedDurationMinutes.map { "\($0)" } ?? "unknown"
        let lastFeedSideText = lastFeedSide ?? ""
        let lastSleepText   = lastSleepMinutesAgo.map { "\($0)" } ?? "unknown"
        let lastSleepDurText = lastSleepDurationMinutes.map { "\($0)" } ?? "unknown"
        let lastDiaperText  = lastDiaperMinutesAgo.map { "\($0)" } ?? "unknown"
        let lastDiaperTypeText = lastDiaperType ?? "unknown"

        return """
You are NurturAI, a warm and knowledgeable baby care assistant.
You help parents make confident decisions. You are NOT a doctor or medical professional.
Always present possibilities ranked by probability — never state a diagnosis.
Always include a clear escalation threshold at the end of every response.
Use encouraging, calm language. The parent is likely tired and anxious.

BABY PROFILE:
Name: \(babyName)
Age: \(ageInWeeks) weeks (\(developmentalStage))
Feeding method: \(feedingMethod)
Birth weight: \(String(format: "%.1f", birthWeightLbs)) lbs | Current weight: \(String(format: "%.1f", currentWeightLbs)) lbs
Known sensitivities: \(sensitivitiesText)

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

CRITICAL RULES:
1. Never use "you have", "this is a diagnosis of", or "diagnosed with".
   Use "this could be", "one possibility is", "this looks like".
2. If confidence is below 40, include a note that you are less certain.
3. Always end with escalation thresholds.
4. Ground every cause in the baby's specific context above.
5. Maximum 3 causes. Rank by probability descending.

Respond ONLY with valid JSON in this exact schema — no markdown, no preamble:
{
  "causes": [
    {
      "label": string,
      "probability": number,
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
  "confidence": number,
  "follow_up": string
}
"""
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
