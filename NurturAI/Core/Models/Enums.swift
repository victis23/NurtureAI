import Foundation

enum FeedingMethod: String, Codable, CaseIterable {
    case breast, formula, combo

    var displayName: String {
        switch self {
        case .breast:  return "Breastfeeding"
        case .formula: return "Formula"
        case .combo:   return "Combo"
        }
    }
}

enum LogType: String, Codable, CaseIterable {
    case feed, sleep, diaper, mood
}

enum DiaperType: String, Codable, CaseIterable {
    case wet, dirty, both, dry
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
        case .content:  return "Content"
        case .fussy:    return "Fussy"
        case .crying:   return "Crying"
        case .settled:  return "Settled"
        case .sleeping: return "Sleeping"
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
