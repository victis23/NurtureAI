import SwiftUI

struct QuickPicksView: View {
    let onSelect: (String) -> Void

    private let picks = [
        Strings.Assist.QuickPicks.crying,
        Strings.Assist.QuickPicks.wontSleep,
        Strings.Assist.QuickPicks.feedingIssue,
        Strings.Assist.QuickPicks.rash,
        Strings.Assist.QuickPicks.fever,
        Strings.Assist.QuickPicks.gasFussiness
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(picks, id: \.self) { pick in
                        Button {
                            onSelect(pick)
                        } label: {
                            Text(pick)
                                .font(NurturTypography.subheadline)
                                .foregroundStyle(NurturColors.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
