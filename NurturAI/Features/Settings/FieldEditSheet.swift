import SwiftUI

/// "Splash card" sheet for editing a single Baby field. Holds local working
/// drafts so the user's changes only commit if they tap Save — Cancel or
/// swipe-down discards. All option surfaces use the same Liquid Glass
/// language the onboarding flow uses.
struct FieldEditSheet: View {
    let field: EditableField
    let baby: Baby
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Drafts (working copies, applied to baby on Save)

    @State private var nameDraft: String = ""
    @State private var birthDateDraft: Date = .now
    @State private var birthWeightGramsDraft: Int = 0
    @State private var birthWeightPounds: Int = 0
    @State private var birthWeightOunces: Int = 0
    @State private var currentWeightGramsDraft: Int = 0
    @State private var currentWeightPounds: Int = 0
    @State private var currentWeightOunces: Int = 0
    @State private var kidCountDraft: FirstChild = .onlyChild
    @State private var feedingMethodDraft: FeedingMethod = .breast
    @State private var feedingFrequencyDraft: FeedingFrequency = .onDemand
    @State private var solidFoodDraft: SolidFoodStatus = .notYet
    @State private var teethingDraft: TeethingStatus = .unsure
    @State private var bathingDraft: BathingFrequency = .everyFewDays
    @State private var pediatricianDraft: PediatricianVisitFrequency = .everyFewMonths
    @State private var householdDraft: HouseholdType = .preferNotToSay
    @State private var familySupportDraft: FamilySupport = .preferNotToSay
    @State private var wellbeingDraft: EmotionalWellbeing = .preferNotToSay
    @State private var overwhelmDraft: OverwhelmLevel = .preferNotToSay
    @State private var challengesDraft: Set<ChildcareChallenge> = []
    @State private var featuresDraft: Set<DesiredFeature> = []
    @State private var internetUsageDraft: InternetUsageFrequency = .sometimes
    @State private var aiUsageDraft: AIUsageHistory = .never
    @State private var appDiscoveryDraft: AppDiscoverySource = .other

    var body: some View {
        NavigationStack {
            ScrollView {
                editorContent
                    .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(field.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        applyChanges()
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear { loadFromBaby() }
        .presentationDetents(presentationDetents)
        .presentationBackground(.regularMaterial)
        .presentationDragIndicator(.visible)
    }

    private var presentationDetents: Set<PresentationDetent> {
        switch field {
        case .name, .kidCount, .teething:
            return [.medium]
        default:
            return [.medium, .large]
        }
    }

    /// Save is gated for free-text and weight where empty doesn't make sense.
    private var canSave: Bool {
        switch field {
        case .name:
            return !nameDraft.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthWeight:
            return birthWeightGramsDraft > 0
        case .currentWeight:
            return currentWeightGramsDraft > 0
        default:
            return true
        }
    }

    // MARK: - Editor variants

    @ViewBuilder
    private var editorContent: some View {
        switch field {
        case .name:
            TextField("Baby's name", text: $nameDraft)
                .font(NurturTypography.headline)
                .foregroundStyle(NurturColors.textPrimary)
                .padding(18)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                .textInputAutocapitalization(.words)
                .submitLabel(.done)

        case .birthday:
            DatePicker(
                "Birthday",
                selection: $birthDateDraft,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(NurturColors.accent)
            .labelsHidden()
            .padding(12)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

        case .birthWeight:
            WeightWheelPicker(
                pounds: $birthWeightPounds,
                ounces: $birthWeightOunces,
                grams: birthWeightGramsDraft
            )
            .onChange(of: birthWeightPounds) { _, _ in syncBirthWeightGrams() }
            .onChange(of: birthWeightOunces) { _, _ in syncBirthWeightGrams() }

        case .currentWeight:
            WeightWheelPicker(
                pounds: $currentWeightPounds,
                ounces: $currentWeightOunces,
                grams: currentWeightGramsDraft
            )
            .onChange(of: currentWeightPounds) { _, _ in syncCurrentWeightGrams() }
            .onChange(of: currentWeightOunces) { _, _ in syncCurrentWeightGrams() }

        case .kidCount:
            singleSelectList(items: FirstChild.allCases, selection: $kidCountDraft)

        case .feedingMethod:
            singleSelectList(items: FeedingMethod.allCases, selection: $feedingMethodDraft)

        case .feedingFrequency:
            singleSelectList(items: FeedingFrequency.allCases, selection: $feedingFrequencyDraft)

        case .solidFoods:
            singleSelectList(items: SolidFoodStatus.allCases, selection: $solidFoodDraft)

        case .teething:
            singleSelectList(items: TeethingStatus.allCases, selection: $teethingDraft)

        case .bathing:
            singleSelectList(items: BathingFrequency.allCases, selection: $bathingDraft)

        case .pediatrician:
            singleSelectList(items: PediatricianVisitFrequency.allCases, selection: $pediatricianDraft)

        case .household:
            singleSelectList(items: HouseholdType.allCases, selection: $householdDraft)

        case .familySupport:
            singleSelectList(items: FamilySupport.allCases, selection: $familySupportDraft)

        case .wellbeing:
            singleSelectList(items: EmotionalWellbeing.allCases, selection: $wellbeingDraft)

        case .overwhelm:
            singleSelectList(items: OverwhelmLevel.allCases, selection: $overwhelmDraft)

        case .challenges:
            multiSelectList(items: ChildcareChallenge.allCases, selection: $challengesDraft)

        case .features:
            multiSelectList(items: DesiredFeature.allCases, selection: $featuresDraft)

        case .internetUsage:
            singleSelectList(items: InternetUsageFrequency.allCases, selection: $internetUsageDraft)

        case .aiUsage:
            singleSelectList(items: AIUsageHistory.allCases, selection: $aiUsageDraft)

        case .appDiscovery:
            singleSelectList(items: AppDiscoverySource.allCases, selection: $appDiscoveryDraft)
        }
    }

    // MARK: - Reusable selection lists (Liquid Glass rows, matches onboarding)

    private func singleSelectList<T>(items: [T], selection: Binding<T>) -> some View
    where T: Hashable, T: HasDisplayName {
        VStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection.wrappedValue = item
                } label: {
                    HStack {
                        Text(item.displayName)
                            .font(NurturTypography.headline)
                        Spacer()
                        if selection.wrappedValue == item {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(18)
                    .glassEffect(
                        selection.wrappedValue == item
                            ? .regular.tint(NurturColors.accent).interactive()
                            : .regular.interactive(),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(selection.wrappedValue == item ? .white : NurturColors.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.selection, trigger: selection.wrappedValue)
    }

    private func multiSelectList<T>(items: [T], selection: Binding<Set<T>>) -> some View
    where T: Hashable, T: HasDisplayName {
        VStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection.wrappedValue.contains(item)
                Button {
                    if isSelected {
                        selection.wrappedValue.remove(item)
                    } else {
                        selection.wrappedValue.insert(item)
                    }
                } label: {
                    HStack {
                        Text(item.displayName)
                            .font(NurturTypography.headline)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(18)
                    .glassEffect(
                        isSelected
                            ? .regular.tint(NurturColors.accent).interactive()
                            : .regular.interactive(),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.selection, trigger: selection.wrappedValue)
    }

    // MARK: - Load / apply

    private func loadFromBaby() {
        nameDraft = baby.name
        birthDateDraft = baby.birthDate
        birthWeightGramsDraft = baby.birthWeightGrams
        currentWeightGramsDraft = baby.currentWeightGrams
        let bw = poundsAndOunces(fromGrams: baby.birthWeightGrams)
        birthWeightPounds = bw.pounds
        birthWeightOunces = bw.ounces
        let cw = poundsAndOunces(fromGrams: baby.currentWeightGrams)
        currentWeightPounds = cw.pounds
        currentWeightOunces = cw.ounces
        kidCountDraft = baby.isFirstChild ? .onlyChild : .hasSiblings
        feedingMethodDraft = baby.feedingMethod
        feedingFrequencyDraft = baby.feedingFrequency
        solidFoodDraft = baby.solidFoodStatus
        teethingDraft = baby.teethingStatus
        bathingDraft = baby.bathingFrequency
        pediatricianDraft = baby.pediatricianVisitFrequency
        householdDraft = baby.householdType
        familySupportDraft = baby.familySupport
        wellbeingDraft = baby.emotionalWellbeing
        overwhelmDraft = baby.overwhelmLevel
        challengesDraft = Set(baby.childcareChallenges.compactMap(ChildcareChallenge.init(rawValue:)))
        featuresDraft = Set(baby.desiredFeatures.compactMap(DesiredFeature.init(rawValue:)))
        internetUsageDraft = baby.internetUsageFrequency
        aiUsageDraft = baby.aiUsageHistory
        appDiscoveryDraft = baby.appDiscoverySource
    }

    private func applyChanges() {
        switch field {
        case .name:               baby.name = nameDraft.trimmingCharacters(in: .whitespaces)
        case .birthday:           baby.birthDate = birthDateDraft
        case .birthWeight:        baby.birthWeightGrams = birthWeightGramsDraft
        case .currentWeight:      baby.currentWeightGrams = currentWeightGramsDraft
        case .kidCount:           baby.isFirstChild = (kidCountDraft == .onlyChild)
        case .feedingMethod:      baby.feedingMethod = feedingMethodDraft
        case .feedingFrequency:   baby.feedingFrequency = feedingFrequencyDraft
        case .solidFoods:         baby.solidFoodStatus = solidFoodDraft
        case .teething:           baby.teethingStatus = teethingDraft
        case .bathing:            baby.bathingFrequency = bathingDraft
        case .pediatrician:       baby.pediatricianVisitFrequency = pediatricianDraft
        case .household:          baby.householdType = householdDraft
        case .familySupport:      baby.familySupport = familySupportDraft
        case .wellbeing:          baby.emotionalWellbeing = wellbeingDraft
        case .overwhelm:          baby.overwhelmLevel = overwhelmDraft
        case .challenges:         baby.childcareChallenges = challengesDraft.map { $0.rawValue }
        case .features:           baby.desiredFeatures = featuresDraft.map { $0.rawValue }
        case .internetUsage:      baby.internetUsageFrequency = internetUsageDraft
        case .aiUsage:            baby.aiUsageHistory = aiUsageDraft
        case .appDiscovery:       baby.appDiscoverySource = appDiscoveryDraft
        }
    }

    // MARK: - Weight conversion helpers

    private func syncBirthWeightGrams() {
        birthWeightGramsDraft = gramsFromPoundsAndOunces(pounds: birthWeightPounds, ounces: birthWeightOunces)
    }

    private func syncCurrentWeightGrams() {
        currentWeightGramsDraft = gramsFromPoundsAndOunces(pounds: currentWeightPounds, ounces: currentWeightOunces)
    }

    private func gramsFromPoundsAndOunces(pounds: Int, ounces: Int) -> Int {
        Int((Double(pounds) * 453.592 + Double(ounces) * 28.3495).rounded())
    }

    private func poundsAndOunces(fromGrams grams: Int) -> (pounds: Int, ounces: Int) {
        guard grams > 0 else { return (0, 0) }
        let lbsTotal = Double(grams) / 453.592
        let pounds = Int(lbsTotal)
        let ounces = Int(((lbsTotal - Double(pounds)) * 16).rounded())
        return (pounds, ounces)
    }
}

/// Lets the generic select-list helpers accept any of the onboarding enums
/// without 20 overloads. Every onboarding enum already has `displayName`.
protocol HasDisplayName {
    var displayName: String { get }
}

extension FirstChild: HasDisplayName {}
extension FeedingMethod: HasDisplayName {}
extension FeedingFrequency: HasDisplayName {}
extension SolidFoodStatus: HasDisplayName {}
extension TeethingStatus: HasDisplayName {}
extension BathingFrequency: HasDisplayName {}
extension PediatricianVisitFrequency: HasDisplayName {}
extension HouseholdType: HasDisplayName {}
extension FamilySupport: HasDisplayName {}
extension EmotionalWellbeing: HasDisplayName {}
extension OverwhelmLevel: HasDisplayName {}
extension ChildcareChallenge: HasDisplayName {}
extension DesiredFeature: HasDisplayName {}
extension InternetUsageFrequency: HasDisplayName {}
extension AIUsageHistory: HasDisplayName {}
extension AppDiscoverySource: HasDisplayName {}
