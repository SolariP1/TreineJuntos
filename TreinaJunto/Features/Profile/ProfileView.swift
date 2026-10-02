import SwiftUI

struct ProfileView: View {
    var onLogout: () -> Void

    @Environment(\.dependencies) private var dependencies

    @State private var model: ProfileViewModel?
    @State private var showEditSheet = false
    @State private var showPhotoMenu = false
    @State private var showPhotoViewer = false
    @State private var appeared = false
    @State private var statsRevealed = false
    @Namespace private var photoNamespace

    var body: some View {
        ZStack {
            Playful.canvas.ignoresSafeArea()

            switch model?.state {
            case let .loaded(profile):
                loaded(profile)

                if showPhotoViewer {
                    ProfilePhotoViewer(profile: profile, photoNamespace: photoNamespace) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            showPhotoViewer = false
                        }
                    }
                }

            case let .failed(message):
                Text(message)
                    .font(.brand(13))
                    .foregroundStyle(Playful.inkMuted)

            case .none, .idle, .loading:
                ProgressView().controlSize(.large).tint(Palette.accent.base)
            }
        }
        // O visualizador é sobreposto à própria tela, para o
        // matchedGeometryEffect poder voar a foto — por isso a tab bar
        // precisa ser escondida na mão.
        .toolbar(showPhotoViewer ? .hidden : .visible, for: .tabBar)
        .sheet(isPresented: $showEditSheet) {
            if let profile = model?.profile {
                EditProfileView(profile: profile) { editado in
                    Task { await model?.save(editado) }
                }
            }
        }
        .confirmationDialog("Foto de perfil", isPresented: $showPhotoMenu, titleVisibility: .visible) {
            Button("Editar perfil") { showEditSheet = true }
            Button("Ver foto") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showPhotoViewer = true
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .task {
            if model == nil {
                model = ProfileViewModel(repository: dependencies.profiles)
            }
            await model?.load()
            appeared = true
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.3)) {
                statsRevealed = true
            }
        }
    }

    private func loaded(_ profile: UserProfile) -> some View {
        let style = (profile.sports.first ?? .corrida).style

        return ScrollView {
            VStack(spacing: 16) {
                ProfileHeroCard(
                    profile: profile,
                    style: style,
                    photoNamespace: photoNamespace,
                    isViewingPhoto: showPhotoViewer,
                    onTapAvatar: { showPhotoMenu = true }
                )
                .sectionEntrance(appeared, index: 0)

                statsStrip(profile).sectionEntrance(appeared, index: 1)

                BadgesStrip(badges: earnedBadges, appeared: appeared)
                    .sectionEntrance(appeared, index: 2)

                ProfilePhotosCard(
                    photos: profile.photos,
                    style: style,
                    onManage: { showEditSheet = true }
                )
                .sectionEntrance(appeared, index: 3)

                if profile.sports.contains(.musculacao) {
                    routineCard(profile).sectionEntrance(appeared, index: 4)
                }

                ProfileInterestsCard(
                    sports: profile.sports,
                    interests: profile.trainingInterests,
                    style: style,
                    onEdit: { showEditSheet = true }
                )
                .sectionEntrance(appeared, index: 5)

                reviewsCard(profile).sectionEntrance(appeared, index: 6)

                ProfileActionButtons(
                    style: style,
                    onEdit: { showEditSheet = true },
                    onLogout: onLogout
                )
                .sectionEntrance(appeared, index: 7)

                #if DEBUG
                    if let simulator = dependencies.simulator {
                        DebugSimulatorCard(simulator: simulator)
                    }
                #endif
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            // Libera a tab bar flutuante para o último card ser alcançável.
            .padding(.bottom, 90)
        }
    }

    private func statsStrip(_ profile: UserProfile) -> some View {
        HStack(spacing: 10) {
            StatTile(
                value: statsRevealed ? profile.trainings : 0,
                label: "treinos",
                symbol: "figure.run.circle.fill",
                color: Palette.orange.base
            )
            StatTile(
                value: statsRevealed ? profile.partners : 0,
                label: "parceiros",
                symbol: "person.2.fill",
                color: Palette.violet.base
            )
            RatingTile(rating: profile.rating)
        }
    }

    private var earnedBadges: [Badge] {
        [
            Badge(symbol: "flame.fill", label: "7 dias seguidos", ramp: Palette.orange),
            Badge(symbol: "checkmark.seal.fill", label: "Sempre aparece", ramp: Palette.mint),
            Badge(symbol: "sunrise.fill", label: "Madrugador", ramp: Palette.pink),
            Badge(symbol: "medal.fill", label: "Veterano", ramp: Palette.amber)
        ]
    }

    private func routineCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Meu treino")
                Spacer()
                Button("Editar") { showEditSheet = true }
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(Palette.violet.deep)
            }

            WeeklySplitList(days: profile.weeklySplit)
        }
        .padding(18)
        .playfulCard()
    }

    private func reviewsCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Minhas avaliações")
                Spacer()
                RatingPill(rating: profile.rating)
            }

            ReviewsList(reviews: profile.reviews)
        }
        .padding(18)
        .playfulCard()
    }
}

#Preview {
    ProfileView(onLogout: {})
}
