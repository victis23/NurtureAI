import Foundation

/// Identifies which baby/profile field is being edited from Settings.
/// Drives both the row label and the editor variant inside `FieldEditSheet`.
enum EditableField: Identifiable, Hashable, CaseIterable {
    // Baby identity & physical
    case name
    case birthday
    case kidCount
    case birthWeight
    case currentWeight
    case teething
    case solidFoods

    // Daily care
    case feedingMethod
    case feedingFrequency
    case bathing
    case pediatrician

    // Family / household
    case household
    case familySupport
    case challenges

    // Parent emotional state
    case wellbeing
    case overwhelm

    // App preferences / meta
    case features
    case internetUsage
    case aiUsage
    case appDiscovery

    var id: Self { self }

    /// Short label shown in the settings list row (left side).
    var label: String {
        switch self {
        case .name:               return Strings.Settings.Fields.name
        case .birthday:           return Strings.Settings.Fields.birthday
        case .kidCount:           return Strings.Settings.Fields.firstChild
        case .birthWeight:        return Strings.Settings.Fields.birthWeight
        case .currentWeight:      return Strings.Settings.Fields.currentWeight
        case .teething:           return Strings.Settings.Fields.teething
        case .solidFoods:         return Strings.Settings.Fields.solidFoods
        case .feedingMethod:      return Strings.Settings.Fields.feedingMethod
        case .feedingFrequency:   return Strings.Settings.Fields.feedingRhythm
        case .bathing:            return Strings.Settings.Fields.bathing
        case .pediatrician:       return Strings.Settings.Fields.pediatricianVisits
        case .household:          return Strings.Settings.Fields.household
        case .familySupport:      return Strings.Settings.Fields.supportSystem
        case .challenges:         return Strings.Settings.Fields.hardestAspects
        case .wellbeing:          return Strings.Settings.Fields.howYoureFeeling
        case .overwhelm:          return Strings.Settings.Fields.overwhelm
        case .features:           return Strings.Settings.Fields.helpfulFeatures
        case .internetUsage:      return Strings.Settings.Fields.onlineResearch
        case .aiUsage:            return Strings.Settings.Fields.aiExperience
        case .appDiscovery:       return Strings.Settings.Fields.howYouFoundUs
        }
    }

    /// Human-friendly summary of the baby's current value (right side of the row).
    /// For sensitive fields where the user picked `.preferNotToSay`, returns
    /// "Not shared" instead of echoing that copy back.
    func currentValueText(for baby: Baby) -> String {
        switch self {
        case .name:
            return baby.name.isEmpty ? "—" : baby.name
        case .birthday:
            return baby.birthDate.formatted(.dateTime.month(.abbreviated).day().year())
        case .kidCount:
            return baby.isFirstChild ? Strings.Common.yes : Strings.Common.no
        case .birthWeight:
            return weightDescription(grams: baby.birthWeightGrams)
        case .currentWeight:
            return weightDescription(grams: baby.currentWeightGrams)
        case .teething:
            return baby.teethingStatus.displayName
        case .solidFoods:
            return baby.solidFoodStatus.displayName
        case .feedingMethod:
            return baby.feedingMethod.displayName
        case .feedingFrequency:
            return baby.feedingFrequency.displayName
        case .bathing:
            return baby.bathingFrequency.displayName
        case .pediatrician:
            return baby.pediatricianVisitFrequency.displayName
        case .household:
            return notSharedIfPrivate(baby.householdType.displayName, isPrivate: baby.householdType == .preferNotToSay)
        case .familySupport:
            return notSharedIfPrivate(baby.familySupport.displayName, isPrivate: baby.familySupport == .preferNotToSay)
        case .challenges:
            return multiSummary(rawValues: baby.childcareChallenges, decode: ChildcareChallenge.init(rawValue:), name: \.displayName)
        case .wellbeing:
            return notSharedIfPrivate(baby.emotionalWellbeing.displayName, isPrivate: baby.emotionalWellbeing == .preferNotToSay)
        case .overwhelm:
            return notSharedIfPrivate(baby.overwhelmLevel.displayName, isPrivate: baby.overwhelmLevel == .preferNotToSay)
        case .features:
            return multiSummary(rawValues: baby.desiredFeatures, decode: DesiredFeature.init(rawValue:), name: \.displayName)
        case .internetUsage:
            return baby.internetUsageFrequency.displayName
        case .aiUsage:
            return baby.aiUsageHistory.displayName
        case .appDiscovery:
            return baby.appDiscoverySource.displayName
        }
    }

    private func notSharedIfPrivate(_ value: String, isPrivate: Bool) -> String {
        isPrivate ? Strings.Common.notShared : value
    }

    private func weightDescription(grams: Int) -> String {
        guard grams > 0 else { return "—" }
        let lbsTotal = Double(grams) / 453.592
        let pounds = Int(lbsTotal)
        let ounces = Int(((lbsTotal - Double(pounds)) * 16).rounded())
        return Strings.Settings.Fields.weight(pounds: pounds, ounces: ounces)
    }

    private func multiSummary<T>(
        rawValues: [String],
        decode: (String) -> T?,
        name: KeyPath<T, String>
    ) -> String {
        let names = rawValues.compactMap(decode).map { $0[keyPath: name] }
        if names.isEmpty { return Strings.Common.noneSelected }
        if names.count <= 2 { return names.joined(separator: ", ") }
        return Strings.Settings.Fields.moreSummary(first: names[0], second: names[1], extra: names.count - 2)
    }
}
