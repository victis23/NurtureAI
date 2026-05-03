import Foundation
import FirebaseFunctions

/// Decoded payload for the onboarding "first insight" preview screen.
struct OnboardingPreview: Codable {
    let greeting: String
    let focuses: [PreviewFocus]
    let reassurance: String
}

struct PreviewFocus: Codable, Identifiable, Hashable {
    let title: String
    let detail: String
    var id: String { title }
}

/// Generates a one-shot personalized welcome from the parent's onboarding draft.
///
/// Calls the same `askAI` Cloud Function the Assist tab uses but with a system
/// prompt and JSON schema tailored to a "wow, this app already gets me" preview
/// rather than the symptom-analysis schema. Stateless — instantiate per use.
@MainActor
final class OnboardingPreviewService {

    private let functions = Functions.functions()

    func generate(draft: OnboardingViewModel.OnboardingDraft) async throws -> OnboardingPreview {
        let payload: [String: Any] = [
            "query": "Generate my personalized first insight.",
            "systemPrompt": Self.buildSystemPrompt(draft: draft),
        ]

        let result = try await functions.httpsCallable("askAI").call(payload)

        guard let data = result.data as? [String: Any],
              let responseJSON = data["responseJSON"] as? String
        else {
            throw AIError.invalidResponse
        }

        let cleaned = responseJSON
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AIError.parseError
        }

        return try JSONDecoder().decode(OnboardingPreview.self, from: jsonData)
    }

    private static func buildSystemPrompt(draft: OnboardingViewModel.OnboardingDraft) -> String {
        let ageInWeeks = max(
            0,
            Calendar.current.dateComponents([.weekOfYear], from: draft.birthDate, to: .now).weekOfYear ?? 0
        )
        let stage = BabyContext.developmentalStage(ageInWeeks: ageInWeeks)
        let babyName = draft.name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "their baby"
            : draft.name.trimmingCharacters(in: .whitespaces)

        var lines: [String] = []
        lines.append("Baby's name: \(babyName)")
        lines.append("Age: \(ageInWeeks) weeks (\(stage))")
        lines.append("Feeding method: \(draft.feedingMethod.displayName)")
        lines.append(draft.kidCount == .onlyChild
                     ? "First-time parent."
                     : "Experienced parent (has older children).")

        switch draft.familySupport {
        case .strong:           lines.append("Has a strong support system at home.")
        case .occasional:       lines.append("Has occasional support — sometimes parenting solo.")
        case .noSupport:        lines.append("Mostly parenting without nearby support.")
        case .preferNotToSay:   break
        }

        switch draft.emotionalWellbeing {
        case .someHardDays:     lines.append("Has shared they have some hard days.")
        case .struggling:       lines.append("Has indicated they've been struggling emotionally — lead with extra warmth and validation before any practical content.")
        case .doingOkay, .preferNotToSay: break
        }

        switch draft.overwhelmLevel {
        case .sometimes:        lines.append("Sometimes feels overwhelmed.")
        case .often:            lines.append("Often feels overwhelmed — keep guidance calm and small.")
        case .almostAlways:     lines.append("Almost always feels overwhelmed — be especially gentle and concrete; one small step at a time.")
        case .rarely, .preferNotToSay: break
        }

        switch draft.householdType {
        case .singleParent:     lines.append("Solo parent — do not assume a partner is available.")
        case .coParenting:      lines.append("Co-parenting across two households.")
        case .extendedFamily:   lines.append("Lives with extended family who help with care.")
        case .twoParent, .other, .preferNotToSay: break
        }

        switch draft.teethingStatus {
        case .teething:         lines.append("Currently teething.")
        case .notYet, .unsure:  break
        }

        switch draft.solidFoodStatus {
        case .justStarting:     lines.append("Just starting to explore solid foods.")
        case .regularly:        lines.append("Regularly eating solids.")
        case .mostly:           lines.append("Mostly on solids.")
        case .notYet:           break
        }

        if !draft.childcareChallenges.isEmpty {
            let names = draft.childcareChallenges.map { $0.displayName.lowercased() }.joined(separator: ", ")
            lines.append("Self-reported hardest aspects of parenting right now: \(names).")
        }

        let context = lines.joined(separator: "\n")

        return """
You are NurturAI, a warm and knowledgeable baby care assistant. You help parents make confident decisions. You are NOT a doctor or medical professional. Use encouraging, calm language.

The parent has just finished onboarding. Generate a personalized welcome insight that demonstrates your value by referencing the specific information they shared. The goal is to make the parent feel SEEN — that you already understand their unique situation.

PARENT & BABY CONTEXT:
\(context)

GUIDELINES:
1. Open with a warm 1-2 sentence greeting that acknowledges what they shared. If they're a first-time parent, gently celebrate that. If they noted overwhelm or struggling, lead with VALIDATION before anything practical.
2. Provide exactly 3 specific, age-appropriate focus areas tailored to \(babyName)'s age and the parent's stated challenges. Each focus has:
   - title: 3-6 words, concrete (e.g. "Sleep at 6 weeks", "Wind-down rituals", "A 5-minute reset for you")
   - detail: 2-3 sentences with a concrete, gentle, evidence-grounded tip the parent can try today. Reference something they specifically shared.
3. End with a 1-2 sentence reassurance that's warm and personal, using \(babyName)'s name. Speak like a real, caring person — not a brochure.
4. Never give medical advice or diagnoses. Stay practical and kind. Do not include disclaimers or refer to "the app" — speak directly to the parent.
5. Match tone to their emotional state. If struggling or solo, be especially gentle. If experienced, you can be more direct.
6. Avoid generic content. Every sentence should feel earned by something they told you.

Respond ONLY with valid JSON in this exact schema — no markdown, no preamble:
{
  "greeting": string,
  "focuses": [
    { "title": string, "detail": string },
    { "title": string, "detail": string },
    { "title": string, "detail": string }
  ],
  "reassurance": string
}
"""
    }
}
