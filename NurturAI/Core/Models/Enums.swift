import Foundation

enum FeedingMethod: String, Codable, CaseIterable {
    case breast, formula, combo

    var displayName: String {
        switch self {
        case .breast:  return Strings.FeedingMethod.breast
        case .formula: return Strings.FeedingMethod.formula
        case .combo:   return Strings.FeedingMethod.combo
        }
    }
}

enum FirstChild: String, Codable, CaseIterable {
	case onlyChild, hasSiblings

	var displayName: String {
		switch self {
		case .onlyChild: return Strings.ChildCount.hasOneKid
		case .hasSiblings: return Strings.ChildCount.hasManyKids
		}
	}
}

// MARK: - Extended Onboarding Answers
// Populated by the expanded onboarding flow. Each maps 1:1 with a question/screen
// and ultimately feeds Baby state used by the AI context builder.

enum FamilySupport: String, Codable, CaseIterable {
    case strong, occasional, noSupport, preferNotToSay

    var displayName: String {
        switch self {
        case .strong:           return Strings.FamilySupport.strong
        case .occasional:       return Strings.FamilySupport.occasional
        case .noSupport:        return Strings.FamilySupport.noSupport
        case .preferNotToSay:   return Strings.FamilySupport.preferNotToSay
        }
    }
}

enum OverwhelmLevel: String, Codable, CaseIterable {
    case rarely, sometimes, often, almostAlways, preferNotToSay

    var displayName: String {
        switch self {
        case .rarely:           return Strings.OverwhelmLevel.rarely
        case .sometimes:        return Strings.OverwhelmLevel.sometimes
        case .often:            return Strings.OverwhelmLevel.often
        case .almostAlways:     return Strings.OverwhelmLevel.almostAlways
        case .preferNotToSay:   return Strings.OverwhelmLevel.preferNotToSay
        }
    }
}

enum EmotionalWellbeing: String, Codable, CaseIterable {
    case doingOkay, someHardDays, struggling, preferNotToSay

    var displayName: String {
        switch self {
        case .doingOkay:        return Strings.EmotionalWellbeing.doingOkay
        case .someHardDays:     return Strings.EmotionalWellbeing.someHardDays
        case .struggling:       return Strings.EmotionalWellbeing.struggling
        case .preferNotToSay:   return Strings.EmotionalWellbeing.preferNotToSay
        }
    }
}

enum HouseholdType: String, Codable, CaseIterable {
    case twoParent, singleParent, coParenting, extendedFamily, other, preferNotToSay

    var displayName: String {
        switch self {
        case .twoParent:        return Strings.HouseholdType.twoParent
        case .singleParent:     return Strings.HouseholdType.singleParent
        case .coParenting:      return Strings.HouseholdType.coParenting
        case .extendedFamily:   return Strings.HouseholdType.extendedFamily
        case .other:            return Strings.HouseholdType.other
        case .preferNotToSay:   return Strings.HouseholdType.preferNotToSay
        }
    }
}

enum DesiredFeature: String, Codable, CaseIterable {
    case sleepTracking, feedingTracking, aiAdvice, milestones, growthTracking, diaperTracking, communitySupport

    var displayName: String {
        switch self {
        case .sleepTracking:    return Strings.DesiredFeature.sleepTracking
        case .feedingTracking:  return Strings.DesiredFeature.feedingTracking
        case .aiAdvice:         return Strings.DesiredFeature.aiAdvice
        case .milestones:       return Strings.DesiredFeature.milestones
        case .growthTracking:   return Strings.DesiredFeature.growthTracking
        case .diaperTracking:   return Strings.DesiredFeature.diaperTracking
        case .communitySupport: return Strings.DesiredFeature.communitySupport
        }
    }
}

enum InternetUsageFrequency: String, Codable, CaseIterable {
    case rarely, sometimes, daily, manyTimesDaily

    var displayName: String {
        switch self {
        case .rarely:           return Strings.InternetUsageFrequency.rarely
        case .sometimes:        return Strings.InternetUsageFrequency.sometimes
        case .daily:            return Strings.InternetUsageFrequency.daily
        case .manyTimesDaily:   return Strings.InternetUsageFrequency.manyTimesDaily
        }
    }
}

enum AppDiscoverySource: String, Codable, CaseIterable {
    case friendOrFamily, appStore, socialMedia, advertisement, webSearch, other

    var displayName: String {
        switch self {
        case .friendOrFamily:   return Strings.AppDiscoverySource.friendOrFamily
        case .appStore:         return Strings.AppDiscoverySource.appStore
        case .socialMedia:      return Strings.AppDiscoverySource.socialMedia
        case .advertisement:    return Strings.AppDiscoverySource.advertisement
        case .webSearch:        return Strings.AppDiscoverySource.webSearch
        case .other:            return Strings.AppDiscoverySource.other
        }
    }
}

enum TeethingStatus: String, Codable, CaseIterable {
    case teething, notYet, unsure

    var displayName: String {
        switch self {
        case .teething:         return Strings.TeethingStatus.teething
        case .notYet:           return Strings.TeethingStatus.notYet
        case .unsure:           return Strings.TeethingStatus.unsure
        }
    }
}

enum SolidFoodStatus: String, Codable, CaseIterable {
    case notYet, justStarting, regularly, mostly

    var displayName: String {
        switch self {
        case .notYet:           return Strings.SolidFoodStatus.notYet
        case .justStarting:     return Strings.SolidFoodStatus.justStarting
        case .regularly:        return Strings.SolidFoodStatus.regularly
        case .mostly:           return Strings.SolidFoodStatus.mostly
        }
    }
}

enum PediatricianVisitFrequency: String, Codable, CaseIterable {
    case whenSick, everyFewMonths, monthly, frequently

    var displayName: String {
        switch self {
        case .whenSick:         return Strings.PediatricianVisitFrequency.whenSick
        case .everyFewMonths:   return Strings.PediatricianVisitFrequency.everyFewMonths
        case .monthly:          return Strings.PediatricianVisitFrequency.monthly
        case .frequently:       return Strings.PediatricianVisitFrequency.frequently
        }
    }
}

enum FeedingFrequency: String, Codable, CaseIterable {
    case every2Hours, every3Hours, every4Hours, onDemand, varies

    var displayName: String {
        switch self {
        case .every2Hours:      return Strings.FeedingFrequency.every2Hours
        case .every3Hours:      return Strings.FeedingFrequency.every3Hours
        case .every4Hours:      return Strings.FeedingFrequency.every4Hours
        case .onDemand:         return Strings.FeedingFrequency.onDemand
        case .varies:           return Strings.FeedingFrequency.varies
        }
    }
}

enum ChildcareChallenge: String, Codable, CaseIterable {
    case feeding, sleeping, diapering, soothing, selfCare, allOfIt

    var displayName: String {
        switch self {
        case .feeding:          return Strings.ChildcareChallenge.feeding
        case .sleeping:         return Strings.ChildcareChallenge.sleeping
        case .diapering:        return Strings.ChildcareChallenge.diapering
        case .soothing:         return Strings.ChildcareChallenge.soothing
        case .selfCare:         return Strings.ChildcareChallenge.selfCare
        case .allOfIt:          return Strings.ChildcareChallenge.allOfIt
        }
    }
}

enum BathingFrequency: String, Codable, CaseIterable {
    case daily, everyFewDays, weekly, asNeeded

    var displayName: String {
        switch self {
        case .daily:            return Strings.BathingFrequency.daily
        case .everyFewDays:     return Strings.BathingFrequency.everyFewDays
        case .weekly:           return Strings.BathingFrequency.weekly
        case .asNeeded:         return Strings.BathingFrequency.asNeeded
        }
    }
}

enum AIUsageHistory: String, Codable, CaseIterable {
    case regularly, occasionally, onceOrTwice, never

    var displayName: String {
        switch self {
        case .regularly:        return Strings.AIUsageHistory.regularly
        case .occasionally:     return Strings.AIUsageHistory.occasionally
        case .onceOrTwice:      return Strings.AIUsageHistory.onceOrTwice
        case .never:            return Strings.AIUsageHistory.never
        }
    }
}

enum LogType: String, Codable, CaseIterable {
    case feed, sleep, diaper, mood
}

enum DiaperType: String, Codable, CaseIterable {
    case wet, dirty, both, dry, none
}

enum FeedSide: String, Codable, CaseIterable {
    case left, right, bottle, both
}

enum MoodState: String, Codable, CaseIterable {
    case content, fussy, crying, settled, sleeping

    var emoji: String {
        switch self {
        case .content:  return "😊"
        case .fussy:    return "😣"
        case .crying:   return "😢"
        case .settled:  return "😌"
        case .sleeping: return "😴"
        }
    }

    var label: String {
        switch self {
        case .content:  return Strings.Mood.content
        case .fussy:    return Strings.Mood.fussy
        case .crying:   return Strings.Mood.crying
        case .settled:  return Strings.Mood.settled
        case .sleeping: return Strings.Mood.sleeping
        }
    }
}

enum SleepTrend: String, Codable {
    case improving, declining, stable
}

// Discriminated union for log metadata encoded as JSON with a "type" key
enum LogMetadata: Codable {
    case none
    case feed(side: FeedSide, bottleML: Int?)
    case sleep(quality: Int?)
    case diaper(type: DiaperType)
    case mood(state: MoodState, notes: String?)

    private enum CodingKeys: String, CodingKey {
        case type, side, bottleML, quality, diaperType, state, notes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode("none", forKey: .type)
        case .feed(let side, let bottleML):
            try container.encode("feed", forKey: .type)
            try container.encode(side, forKey: .side)
            try container.encodeIfPresent(bottleML, forKey: .bottleML)
        case .sleep(let quality):
            try container.encode("sleep", forKey: .type)
            try container.encodeIfPresent(quality, forKey: .quality)
        case .diaper(let diaperType):
            try container.encode("diaper", forKey: .type)
            try container.encode(diaperType, forKey: .diaperType)
        case .mood(let state, let notes):
            try container.encode("mood", forKey: .type)
            try container.encode(state, forKey: .state)
            try container.encodeIfPresent(notes, forKey: .notes)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        switch typeString {
        case "feed":
            let side = try container.decode(FeedSide.self, forKey: .side)
            let bottleML = try container.decodeIfPresent(Int.self, forKey: .bottleML)
            self = .feed(side: side, bottleML: bottleML)
        case "sleep":
            let quality = try container.decodeIfPresent(Int.self, forKey: .quality)
            self = .sleep(quality: quality)
        case "diaper":
            let diaperType = try container.decode(DiaperType.self, forKey: .diaperType)
            self = .diaper(type: diaperType)
        case "mood":
            let state = try container.decode(MoodState.self, forKey: .state)
            let notes = try container.decodeIfPresent(String.self, forKey: .notes)
            self = .mood(state: state, notes: notes)
        default:
            self = .none
        }
    }
}
