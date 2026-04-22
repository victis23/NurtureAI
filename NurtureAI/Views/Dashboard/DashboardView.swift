import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(DependencyContainer.self) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    DashboardContentView(viewModel: vm, baby: baby)
                } else {
                    ContentUnavailableView("No baby profile", systemImage: "person.crop.circle")
                }
            }
            .navigationTitle(babies.first?.name ?? "Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .task {
            guard let baby = babies.first else { return }
            let vm = DashboardViewModel(
                contextBuilder: container.contextBuilder,
                patternService: container.patternService,
                feedingRepo: container.feedingLogRepository,
                sleepRepo: container.sleepLogRepository,
                diaperRepo: container.diaperLogRepository
            )
            viewModel = vm
            await vm.load(baby: baby)
        }
    }
}

private struct DashboardContentView: View {
    @Bindable var viewModel: DashboardViewModel
    let baby: Baby

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Age card
                DashboardCard(title: baby.ageDescription, subtitle: baby.birthDate.formatted(date: .long, time: .omitted), icon: "birthday.cake", color: NurturColors.accent)

                // Feeding status
                DashboardCard(
                    title: viewModel.timeSinceLastFeedDisplay,
                    subtitle: "Last feeding",
                    icon: "drop.fill",
                    color: NurturColors.info,
                    badge: viewModel.nextFeedDisplay
                )

                // Sleep status
                DashboardCard(
                    title: viewModel.timeSinceLastSleepDisplay,
                    subtitle: "Sleep status",
                    icon: "moon.fill",
                    color: NurturColors.accent,
                    badge: viewModel.isOvertired ? "Overtired?" : nil
                )

                // Stats row
                HStack(spacing: 12) {
                    DashboardCard(title: "\(viewModel.patterns.feedingsIn24h)", subtitle: "Feeds today", icon: "drop.fill", color: NurturColors.info)
                    DashboardCard(title: viewModel.patterns.avgNapDurationDisplay, subtitle: "Avg nap", icon: "moon.zzz.fill", color: NurturColors.accent)
                }

                if viewModel.isLoading {
                    ProgressView().padding()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh(baby: baby)
        }
    }
}

private struct DashboardCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var badge: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(NurturTypography.headline)
                Text(subtitle).font(NurturTypography.caption).foregroundStyle(NurturColors.textSecondary)
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(NurturTypography.caption2)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(color.opacity(0.15), in: Capsule())
                    .foregroundStyle(color)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
