import SwiftUI

struct QuickPicksView: View {
    let onSelect: (String) -> Void

    private let picks = [
        "Crying", "Won't sleep", "Feeding issue",
        "Rash", "Fever", "Gas/Fussiness"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(picks, id: \.self) { pick in
                    Button {
                        onSelect(pick)
                    } label: {
                        Text(pick)
                            .font(NurturTypography.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(NurturColors.surfaceWarm, in: Capsule())
                            .foregroundStyle(NurturColors.textPrimary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
