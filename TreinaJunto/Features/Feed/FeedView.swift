import SwiftUI

struct FeedView: View {
    @Environment(\.dependencies) private var dependencies

    @State private var model: FeedViewModel?
    @State private var showAvailabilitySheet = false
    @State private var selectedPortfolio: PartnerPortfolio?
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Playful.canvas.ignoresSafeArea()

                if let model {
                    content(model)

                    if let message = model.toastMessage {
                        ToastView(message: message)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedPortfolio) { portfolio in
                PartnerPortfolioView(portfolio: portfolio) {
                    Task { await model?.invite(portfolio.partner) }
                    selectedPortfolio = nil
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model?.toastMessage)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: model?.invites.count)
        .sheet(isPresented: $showAvailabilitySheet) {
            MarkAvailabilitySheet { sport, time in
                Task { await model?.publishAvailability(sport: sport, when: time) }
            }
        }
        .task {
            // O modelo nasce aqui porque depende do Environment, que não está
            // disponível na inicialização da View.
            if model == nil {
                model = FeedViewModel(
                    partnerRepository: dependencies.partners,
                    inviteRepository: dependencies.invites
                )
            }
            await model?.load()
            appeared = true
        }
    }

    @ViewBuilder
    private func content(_ model: FeedViewModel) -> some View {
        switch model.partners {
        case .idle, .loading:
            ProgressView()
                .controlSize(.large)
                .tint(Palette.accent.base)

        case let .failed(message):
            FeedErrorView(message: message) {
                Task { await model.load() }
            }

        case let .loaded(people):
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greeting(model).sectionEntrance(appeared, index: 0)
                    openWorkoutCard.sectionEntrance(appeared, index: 1)

                    if !model.invites.isEmpty {
                        inviteSection(model).sectionEntrance(appeared, index: 2)
                    }

                    nearbySection(model, people: people).sectionEntrance(appeared, index: 3)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                // Libera a tab bar flutuante para o último card ser alcançável.
                .padding(.bottom, 90)
            }
        }
    }

    // MARK: - Greeting

    private func greeting(_ model: FeedViewModel) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.avatarGradients[1])
                Text("L").font(.display(15)).foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Olá, Lucas 👋")
                    .font(.display(17, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                Text(todayLabel)
                    .font(.brand(11.5, weight: .medium))
                    .foregroundStyle(Playful.inkMuted)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                    .frame(width: 42, height: 42)
                    .background(Playful.surface, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if !model.invites.isEmpty {
                            Text("\(model.invites.count)")
                                .font(.brand(9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 17, height: 17)
                                .background(Palette.accent.base, in: Circle())
                                .overlay(Circle().stroke(Playful.canvas, lineWidth: 2))
                                .offset(x: 3, y: -3)
                        }
                    }
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
            .buttonStyle(.pressable)
        }
    }

    // MARK: - Hero: abrir um treino

    private var openWorkoutCard: some View {
        let style = Palette.violet

        return Button { showAvailabilitySheet = true } label: {
            ZStack(alignment: .topLeading) {
                FloatingBlob(color: .white.opacity(0.16), size: 170, lobes: 6, speed: 10)
                    .offset(x: 200, y: 30)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bora treinar hoje?")
                            .font(.display(19, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                        Text("Marque um treino e apareça pra quem está perto agora.")
                            .font(.brand(12))
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill").font(.system(size: 11, weight: .bold))
                            Text("Marcar treino agora").font(.brand(12.5, weight: .bold))
                        }
                        .foregroundStyle(style.deep)
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(.white, in: Capsule())
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 0)

                    MascotView(
                        color: .white.opacity(0.95),
                        deepColor: .white.opacity(0.72),
                        size: 86,
                        mood: .happy
                    )
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .background(style.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: style.base.opacity(0.35), radius: 20, y: 12)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Convites

    private func inviteSection(_ model: FeedViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text("Convites recebidos")
                    .font(.display(14, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                Text("\(model.invites.count)")
                    .font(.brand(10.5, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2.5)
                    .background(Palette.accent.base, in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.invites) { invite in
                        InviteCardView(
                            invite: invite,
                            onAccept: { Task { await model.respond(to: invite, accepted: true) } },
                            onDecline: { Task { await model.respond(to: invite, accepted: false) } }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Perto de você

    private func nearbySection(_ model: FeedViewModel, people: [WorkoutPartner]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.accent.base)
                Text("Perto de você")
                    .font(.display(14, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                Spacer()
                Text("\(people.count) agora")
                    .font(.brand(11, weight: .medium))
                    .foregroundStyle(Playful.inkMuted)
            }

            VStack(spacing: 10) {
                ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                    PersonCardView(
                        person: person,
                        isInvited: model.hasInvited(person),
                        onInvite: { Task { await model.invite(person) } },
                        onOpenProfile: {
                            Task { selectedPortfolio = await model.portfolio(for: person) }
                        }
                    )
                    .scaleEffect(appeared ? 1 : 0.94)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.78).delay(0.25 + Double(index) * 0.07),
                        value: appeared
                    )
                }
            }
        }
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        // Só a primeira letra — `.capitalized` daria "Terça-Feira, 22 De Setembro".
        let raw = formatter.string(from: Date())
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

/// O que aparece quando o Feed não consegue carregar.
private struct FeedErrorView: View {
    let message: String
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            MascotView(
                color: Palette.orange.base,
                deepColor: Palette.orange.deep,
                size: 100,
                mood: .sleepy
            )

            Text(message)
                .font(.brand(13))
                .foregroundStyle(Playful.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Tentar de novo", action: onRetry)
                .font(.brand(13.5, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Palette.accent.base, in: Capsule())
                .buttonStyle(.pressable)
        }
    }
}

#Preview {
    FeedView()
}
