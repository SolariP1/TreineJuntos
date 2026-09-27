import SwiftUI

struct PartnerPortfolioView: View {
    let partner: WorkoutPartner
    var onInvite: () -> Void

    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var model: PartnerPortfolioViewModel?
    @State private var appeared = false
    @State private var statsRevealed = false

    private var style: SportStyle {
        partner.sport.style
    }

    var body: some View {
        ZStack {
            Playful.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    topBar

                    // O topo desenha com o que o Feed já sabe da pessoa, então
                    // a navegação nunca mostra uma tela em branco.
                    PortfolioHeroCard(
                        partner: partner,
                        bio: model?.state.value?.bio ?? "",
                        compatibility: model?.state.value?.compatibility ?? 0,
                        style: style,
                        statsRevealed: statsRevealed
                    )
                    .sectionEntrance(appeared, index: 0)

                    switch model?.state {
                    case let .loaded(portfolio):
                        details(portfolio)

                    case let .failed(message):
                        Text(message)
                            .font(.brand(13))
                            .foregroundStyle(Playful.inkMuted)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)

                    case .none, .idle, .loading:
                        ProgressView()
                            .controlSize(.large)
                            .tint(style.base)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PortfolioInviteBar(partnerName: partner.name, style: style, onInvite: onInvite)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            if model == nil {
                model = PartnerPortfolioViewModel(partner: partner, repository: dependencies.partners)
            }
            await model?.load()
            appeared = true
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.3)) {
                statsRevealed = true
            }
        }
    }

    @ViewBuilder
    private func details(_ portfolio: PartnerPortfolio) -> some View {
        statsStrip(portfolio).sectionEntrance(appeared, index: 1)

        BadgesStrip(badges: badges(for: portfolio), appeared: appeared)
            .sectionEntrance(appeared, index: 2)

        TrainingCalendarCard(
            days: portfolio.days,
            dayPartners: portfolio.dayPartners,
            style: style,
            appeared: appeared
        )
        .sectionEntrance(appeared, index: 3)

        if !portfolio.weeklySplit.isEmpty {
            routineCard(portfolio).sectionEntrance(appeared, index: 4)
        }

        PortfolioInterestsCard(interests: portfolio.interests, style: style)
            .sectionEntrance(appeared, index: 5)

        reviewsCard(portfolio).sectionEntrance(appeared, index: 6)
    }

    private var topBar: some View {
        HStack {
            CircleIconButton(symbol: "chevron.left") { dismiss() }
            Spacer()
            CircleIconButton(symbol: "square.and.arrow.up") {}
        }
        .padding(.top, 4)
    }

    private func statsStrip(_ portfolio: PartnerPortfolio) -> some View {
        HStack(spacing: 10) {
            StatTile(
                value: statsRevealed ? portfolio.streak : 0,
                label: "dias seguidos",
                symbol: "flame.fill",
                color: Palette.orange.base,
                pulses: true
            )
            StatTile(
                value: statsRevealed ? portfolio.totalTrainings : 0,
                label: "treinos",
                symbol: "figure.run.circle.fill",
                color: Palette.violet.base
            )
            StatTile(
                value: statsRevealed ? portfolio.reliability : 0,
                suffix: "%",
                label: "confiável",
                symbol: "checkmark.seal.fill",
                color: Palette.mint.base
            )
        }
    }

    private func badges(for portfolio: PartnerPortfolio) -> [Badge] {
        var earned: [Badge] = []
        if portfolio.streak >= 5 {
            earned.append(
                Badge(
                    symbol: "flame.fill",
                    label: "Sequência de \(portfolio.streak)",
                    ramp: Palette.orange
                )
            )
        }
        if portfolio.reliability >= 70 {
            earned.append(Badge(symbol: "checkmark.seal.fill", label: "Sempre aparece", ramp: Palette.mint))
        }
        if portfolio.totalTrainings >= 20 {
            earned.append(Badge(symbol: "medal.fill", label: "Veterano", ramp: Palette.amber))
        }
        earned.append(Badge(symbol: "sunrise.fill", label: "Madrugador", ramp: Palette.pink))
        earned.append(Badge(symbol: "heart.fill", label: "Companheiro fiel", ramp: Palette.violet))
        return earned
    }

    private func routineCard(_ portfolio: PartnerPortfolio) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Rotina de musculação")
            WeeklySplitList(days: portfolio.weeklySplit)
        }
        .padding(18)
        .playfulCard()
    }

    private func reviewsCard(_ portfolio: PartnerPortfolio) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Avaliações")
                Spacer()
                RatingPill(rating: portfolio.rating)
            }

            ReviewsList(reviews: portfolio.reviews)
        }
        .padding(18)
        .playfulCard()
    }
}

#Preview {
    NavigationStack {
        PartnerPortfolioView(partner: SampleData.partners[0], onInvite: {})
    }
}
