import SwiftUI

struct ProfileView: View {
    var onLogout: () -> Void

    @State private var profile = SampleData.profile
    @State private var showEditSheet = false
    @State private var showPhotoMenu = false
    @State private var showPhotoViewer = false
    @State private var appeared = false
    @State private var statsRevealed = false
    @Namespace private var photoNamespace

    private var style: SportStyle {
        (profile.sports.first ?? .corrida).style
    }

    var body: some View {
        ZStack {
            Playful.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    hero.sectionEntrance(appeared, index: 0)
                    statsStrip.sectionEntrance(appeared, index: 1)
                    badgesStrip.sectionEntrance(appeared, index: 2)
                    photosCard.sectionEntrance(appeared, index: 3)
                    if profile.sports.contains(.musculacao) {
                        routineCard.sectionEntrance(appeared, index: 4)
                    }
                    interestsCard.sectionEntrance(appeared, index: 5)
                    reviewsCard.sectionEntrance(appeared, index: 6)
                    actionButtons.sectionEntrance(appeared, index: 7)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                // Clears the floating tab bar so the last card is reachable.
                .padding(.bottom, 90)
            }

            if showPhotoViewer {
                photoViewer
            }
        }
        // The viewer is an in-view overlay (so matchedGeometryEffect can fly the
        // photo), which means the tab bar has to be hidden by hand.
        .toolbar(showPhotoViewer ? .hidden : .visible, for: .tabBar)
        .sheet(isPresented: $showEditSheet) {
            EditProfileView(profile: $profile)
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
        .onAppear {
            appeared = true
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.3)) {
                statsRevealed = true
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack {
            FloatingBlob(color: .white.opacity(0.18), size: 200, lobes: 6, speed: 11)
                .offset(x: -105, y: -45)
            FloatingBlob(color: .white.opacity(0.12), size: 150, lobes: 4, speed: 8)
                .offset(x: 115, y: 60)

            VStack(spacing: 13) {
                Button {
                    showPhotoMenu = true
                } label: {
                    ZStack {
                        BlobShape(phase: 0.9, lobes: 6, amplitude: 0.07)
                            .fill(.white.opacity(0.28))
                            .frame(width: 118, height: 118)

                        avatarContent
                            .frame(width: 98, height: 98)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 4))
                            .matchedGeometryEffect(
                                id: "profilePhoto",
                                in: photoNamespace,
                                isSource: !showPhotoViewer
                            )

                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(style.deep)
                            .frame(width: 28, height: 28)
                            .background(.white, in: Circle())
                            .offset(x: 36, y: 36)
                    }
                }
                .buttonStyle(.pressable)

                VStack(spacing: 6) {
                    Text(profile.name)
                        .font(.display(23, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.system(size: 10))
                        Text(profile.city).font(.brand(12, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.22), in: Capsule())

                    Text(profile.bio)
                        .font(.brand(12.5))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 26)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [style.base, style.deep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: style.base.opacity(0.35), radius: 24, y: 14)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let first = profile.photos.first, let image = UIImage(data: first) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.25, green: 0.68, blue: 0.45),
                        Color(red: 0.12, green: 0.48, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(String(profile.name.prefix(1)))
                    .font(.display(34))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Photo viewer

    private var photoViewer: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()
                .transition(.opacity)

            avatarContent
                .frame(width: 320, height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .matchedGeometryEffect(id: "profilePhoto", in: photoNamespace, isSource: showPhotoViewer)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            showPhotoViewer = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                }
                Spacer()
            }
            .padding(20)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showPhotoViewer = false
            }
        }
        .zIndex(10)
    }

    // MARK: - Stats

    private var statsStrip: some View {
        HStack(spacing: 10) {
            statTile(
                value: statsRevealed ? profile.trainings : 0,
                suffix: "",
                label: "treinos",
                symbol: "figure.run.circle.fill",
                color: Palette.orange.base
            )
            statTile(
                value: statsRevealed ? profile.partners : 0,
                suffix: "",
                label: "parceiros",
                symbol: "person.2.fill",
                color: Palette.violet.base
            )
            ratingTile
        }
    }

    private func statTile(
        value: Int,
        suffix: String,
        label: String,
        symbol: String,
        color: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 17)).foregroundStyle(color)
            Text("\(value)\(suffix)")
                .font(.mono(19, weight: .bold))
                .foregroundStyle(Playful.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.brand(10, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .playfulCard(Playful.surface, radius: 22, tint: color)
    }

    private var ratingTile: some View {
        VStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 17))
                .foregroundStyle(Palette.amber.base)
            Text(profile.rating)
                .font(.mono(19, weight: .bold))
                .foregroundStyle(Playful.ink)
            Text("nota")
                .font(.brand(10, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .playfulCard(Playful.surface, radius: 22, tint: Palette.amber.base)
    }

    // MARK: - Badges

    private var badgesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(earnedBadges.enumerated()), id: \.offset) { index, badge in
                    HStack(spacing: 6) {
                        Image(systemName: badge.symbol).font(.system(size: 12))
                            .foregroundStyle(badge.ramp.base)
                        Text(badge.label).font(.brand(11.5, weight: .bold)).foregroundStyle(badge.ramp.deep)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(badge.ramp.soft, in: Capsule())
                    .overlay(Capsule().stroke(badge.ramp.base.opacity(0.25), lineWidth: 1))
                    .rotationEffect(.degrees(index % 2 == 0 ? -1.5 : 1.5))
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.6).delay(0.35 + Double(index) * 0.06),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
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

    // MARK: - Photos

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Minhas fotos")
                Spacer()
                Button("Gerenciar") { showEditSheet = true }
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(style.deep)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    if profile.photos.isEmpty {
                        ForEach(0 ..< 3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Playful.canvas)
                                .frame(width: 88, height: 112)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Playful.inkFaint)
                                )
                                .id("placeholder\(index)")
                        }
                    } else {
                        ForEach(Array(profile.photos.enumerated()), id: \.offset) { _, data in
                            Group {
                                if let image = UIImage(data: data) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else {
                                    Rectangle().fill(Playful.canvas)
                                }
                            }
                            .frame(width: 88, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                    Button { showEditSheet = true } label: {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                style.base.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                            )
                            .frame(width: 88, height: 112)
                            .overlay(
                                VStack(spacing: 5) {
                                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                                    Text("Adicionar").font(.brand(10, weight: .semibold))
                                }
                                .foregroundStyle(style.deep)
                            )
                    }
                    .buttonStyle(.pressable)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .playfulCard()
    }

    // MARK: - Routine

    private var routineCard: some View {
        let musc = Palette.violet

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Meu treino")
                Spacer()
                Button("Editar") { showEditSheet = true }
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(musc.deep)
            }

            VStack(spacing: 8) {
                ForEach(profile.weeklySplit) { day in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(day.day.prefix(3).uppercased())
                                .font(.mono(9.5, weight: .bold))
                                .foregroundStyle(musc.deep)
                                .padding(.horizontal, 7).padding(.vertical, 4)
                                .background(musc.soft, in: Capsule())
                            Text(day.focus)
                                .font(.brand(12.5, weight: .bold))
                                .foregroundStyle(Playful.ink)
                            Spacer()
                        }
                        FlowLayout(spacing: 6) {
                            ForEach(day.exercises, id: \.self) { exercise in
                                Text(exercise)
                                    .font(.brand(10, weight: .medium))
                                    .foregroundStyle(Playful.inkMuted)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Playful.canvas, in: Capsule())
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        Playful.canvas.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
            }
        }
        .padding(18)
        .playfulCard()
    }

    // MARK: - Interests

    private var interestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("O que procuro")
                Spacer()
                Button("Editar") { showEditSheet = true }
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(style.deep)
            }

            FlowLayout(spacing: 7) {
                ForEach(profile.sports, id: \.self) { sport in
                    let sportStyle = sport.style
                    HStack(spacing: 5) {
                        Image(systemName: sportStyle.symbol).font(.system(size: 9.5, weight: .semibold))
                        Text(sport.label).font(.brand(11.5, weight: .bold))
                    }
                    .foregroundStyle(sportStyle.deep)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(sportStyle.soft, in: Capsule())
                }

                ForEach(profile.trainingInterests, id: \.self) { interest in
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle").font(.system(size: 9))
                        Text(interest).font(.brand(11.5, weight: .semibold))
                    }
                    .foregroundStyle(Playful.inkMuted)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Playful.canvas, in: Capsule())
                }
            }
        }
        .padding(18)
        .playfulCard()
    }

    // MARK: - Reviews

    private var reviewsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Minhas avaliações")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 11))
                    Text(profile.rating).font(.mono(12, weight: .bold))
                }
                .foregroundStyle(Palette.amber.deep)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(Palette.amber.soft, in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(profile.reviews) { review in
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle().fill(review.gradient)
                            Text(review.initials).font(.display(12)).foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(review.reviewerName)
                                    .font(.brand(12.5, weight: .bold))
                                    .foregroundStyle(Playful.ink)
                                HStack(spacing: 1.5) {
                                    ForEach(0 ..< 5, id: \.self) { index in
                                        Image(systemName: index < review.rating ? "star.fill" : "star")
                                            .font(.system(size: 8))
                                            .foregroundStyle(Palette.amber.base)
                                    }
                                }
                            }
                            Text(review.comment)
                                .font(.brand(11.5))
                                .foregroundStyle(Playful.inkMuted)
                            Text(review.context)
                                .font(.brand(9.5, weight: .medium))
                                .foregroundStyle(Playful.inkFaint)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(
                        Playful.canvas.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
            }
        }
        .padding(18)
        .playfulCard()
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button { showEditSheet = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil").font(.system(size: 13, weight: .semibold))
                    Text("Editar perfil").font(.brand(14.5, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .background(
                LinearGradient(colors: [style.base, style.deep], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: style.base.opacity(0.35), radius: 14, y: 8)
            .buttonStyle(.pressable)

            Button(action: onLogout) {
                Text("Sair")
                    .font(.brand(13.5, weight: .semibold))
                    .foregroundStyle(Playful.inkMuted)
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .background(Playful.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .buttonStyle(.pressable)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.display(14, weight: .semibold))
            .foregroundStyle(Playful.ink)
    }
}

#Preview {
    ProfileView(onLogout: {})
}
