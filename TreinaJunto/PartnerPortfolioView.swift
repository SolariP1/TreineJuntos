import SwiftUI

struct PartnerPortfolioView: View {
    let portfolio: PartnerPortfolio
    var onInvite: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var statsRevealed = false
    @State private var selectedDay: Int?

    private var style: SportStyle { Playful.style(for: portfolio.partner.sport) }

    var body: some View {
        ZStack {
            Playful.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    topBar
                    hero.sectionEntrance(appeared, index: 0)
                    statsStrip.sectionEntrance(appeared, index: 1)
                    badgesStrip.sectionEntrance(appeared, index: 2)
                    calendarCard.sectionEntrance(appeared, index: 3)
                    if !portfolio.weeklySplit.isEmpty {
                        routineCard.sectionEntrance(appeared, index: 4)
                    }
                    interestsCard.sectionEntrance(appeared, index: 5)
                    reviewsCard.sectionEntrance(appeared, index: 6)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) { inviteBar }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            appeared = true
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.3)) {
                statsRevealed = true
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            circleButton("chevron.left") { dismiss() }
            Spacer()
            circleButton("square.and.arrow.up") {}
        }
        .padding(.top, 4)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Playful.ink)
                .frame(width: 44, height: 44)
                .background(Playful.surface, in: Circle())
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack {
            // Ambient blobs drifting behind the content
            FloatingBlob(color: .white.opacity(0.18), size: 210, lobes: 6, speed: 11)
                .offset(x: -110, y: -50)
            FloatingBlob(color: .white.opacity(0.12), size: 150, lobes: 4, speed: 8)
                .offset(x: 120, y: 60)

            VStack(spacing: 14) {
                ZStack {
                    BlobShape(phase: 0.9, lobes: 6, amplitude: 0.07)
                        .fill(.white.opacity(0.28))
                        .frame(width: 116, height: 116)
                    Circle()
                        .fill(portfolio.partner.gradient)
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 4))
                    Text(portfolio.partner.initials)
                        .font(.display(34))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text("\(portfolio.partner.name), \(portfolio.partner.age)")
                        .font(.display(24, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        badge(symbol: style.symbol, text: portfolio.partner.sport)
                        badge(symbol: "location.fill", text: portfolio.partner.distance)
                    }

                    Text(portfolio.bio)
                        .font(.brand(12.5))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 2)
                }

                compatibilityPill
            }
            .padding(.vertical, 26)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [style.base, style.deep], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: style.base.opacity(0.35), radius: 24, y: 14)
    }

    private func badge(symbol: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold))
            Text(text).font(.brand(11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.22), in: Capsule())
    }

    private var compatibilityPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(style.deep)
            Text("\(statsRevealed ? portfolio.compatibility : 0)% compatível com você")
                .font(.brand(12.5, weight: .bold))
                .foregroundStyle(style.deep)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.white, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }

    // MARK: - Stats

    private var statsStrip: some View {
        HStack(spacing: 10) {
            statTile(
                value: statsRevealed ? portfolio.streak : 0,
                suffix: "",
                label: "dias seguidos",
                symbol: "flame.fill",
                color: Playful.style(for: "Corrida").base,
                pulses: true
            )
            statTile(
                value: statsRevealed ? portfolio.totalTrainings : 0,
                suffix: "",
                label: "treinos",
                symbol: "figure.run.circle.fill",
                color: Playful.style(for: "Musculação").base,
                pulses: false
            )
            statTile(
                value: statsRevealed ? portfolio.reliability : 0,
                suffix: "%",
                label: "confiável",
                symbol: "checkmark.seal.fill",
                color: Playful.style(for: "Funcional").base,
                pulses: false
            )
        }
    }

    private func statTile(value: Int, suffix: String, label: String, symbol: String, color: Color, pulses: Bool) -> some View {
        VStack(spacing: 6) {
            Group {
                if pulses {
                    Image(systemName: symbol)
                        .font(.system(size: 17))
                        .foregroundStyle(color)
                        .phaseAnimator([1.0, 1.18]) { content, scale in
                            content.scaleEffect(scale)
                        } animation: { _ in .easeInOut(duration: 0.9) }
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 17))
                        .foregroundStyle(color)
                }
            }

            Text("\(value)\(suffix)")
                .font(.mono(19, weight: .bold))
                .foregroundStyle(Playful.ink)
                .contentTransition(.numericText())

            Text(label)
                .font(.brand(10, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .playfulCard(Playful.surface, radius: 22, tint: color)
    }

    // MARK: - Badges

    private var badges: [(String, String, SportStyle)] {
        var earned: [(String, String, SportStyle)] = []
        if portfolio.streak >= 5 {
            earned.append(("flame.fill", "Sequência de \(portfolio.streak)", Playful.style(for: "Corrida")))
        }
        if portfolio.reliability >= 70 {
            earned.append(("checkmark.seal.fill", "Sempre aparece", Playful.style(for: "Funcional")))
        }
        if portfolio.totalTrainings >= 20 {
            earned.append(("medal.fill", "Veterano", Playful.style(for: "Ciclismo")))
        }
        earned.append(("sunrise.fill", "Madrugador", Playful.style(for: "Yoga")))
        earned.append(("heart.fill", "Companheiro fiel", Playful.style(for: "Musculação")))
        return earned
    }

    private var badgesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(badges.enumerated()), id: \.offset) { index, badge in
                    HStack(spacing: 6) {
                        Image(systemName: badge.0)
                            .font(.system(size: 12))
                            .foregroundStyle(badge.2.base)
                        Text(badge.1)
                            .font(.brand(11.5, weight: .bold))
                            .foregroundStyle(badge.2.deep)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(badge.2.soft, in: Capsule())
                    .overlay(Capsule().stroke(badge.2.base.opacity(0.25), lineWidth: 1))
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

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Histórico de treinos")
                Spacer()
                Text(monthName)
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(Playful.inkMuted)
            }

            HStack(spacing: 0) {
                ForEach(["D", "S", "T", "Q", "Q", "S", "S"], id: \.self) { symbol in
                    Text(symbol)
                        .font(.brand(10, weight: .bold))
                        .foregroundStyle(Playful.inkFaint)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(0..<leadingBlanks, id: \.self) { index in
                    Color.clear.frame(height: 38).id("blank\(index)")
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(day)
                }
            }

            legend
        }
        .padding(18)
        .playfulCard(Playful.surface, tint: style.base)
    }

    private func dayCell(_ day: Int) -> some View {
        let state = portfolio.days[day] ?? .idle
        let isToday = day == todayNumber
        let isSelected = selectedDay == day

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                selectedDay = isSelected ? nil : day
            }
        } label: {
            ZStack {
                switch state {
                case .trainedTogether:
                    Circle().fill(style.base)
                case .openedAlone:
                    Circle()
                        .strokeBorder(style.base.opacity(0.55), style: StrokeStyle(lineWidth: 1.6, dash: [3, 3]))
                case .idle:
                    Circle().fill(Playful.canvas)
                }

                Text("\(day)")
                    .font(.mono(11, weight: state == .trainedTogether ? .bold : .medium))
                    .foregroundStyle(dayTextColor(state))

                if state == .trainedTogether, let initial = portfolio.dayPartners[day] {
                    Text(initial)
                        .font(.brand(7.5, weight: .bold))
                        .foregroundStyle(style.deep)
                        .frame(width: 14, height: 14)
                        .background(.white, in: Circle())
                        .offset(x: 12, y: -12)
                }
            }
            .frame(height: 38)
            .overlay(
                Circle()
                    .stroke(Playful.ink.opacity(isToday ? 0.5 : 0), lineWidth: 1.5)
                    .padding(-3)
            )
            .scaleEffect(isSelected ? 1.16 : 1)
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.7).delay(Double(day) * 0.012 + 0.2),
                value: appeared
            )
        }
        .buttonStyle(.plain)
    }

    private func dayTextColor(_ state: TrainingDayState) -> Color {
        switch state {
        case .trainedTogether: return .white
        case .openedAlone: return style.deep
        case .idle: return Playful.inkFaint
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(fill: true, text: "Treinou junto")
            legendItem(fill: false, text: "Abriu, sem parceiro")
            HStack(spacing: 5) {
                Circle().fill(Playful.canvas).frame(width: 11, height: 11)
                Text("Sem treino").font(.brand(9.5, weight: .medium)).foregroundStyle(Playful.inkMuted)
            }
        }
        .padding(.top, 2)
    }

    private func legendItem(fill: Bool, text: String) -> some View {
        HStack(spacing: 5) {
            Group {
                if fill {
                    Circle().fill(style.base)
                } else {
                    Circle().strokeBorder(style.base.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, dash: [2.5, 2.5]))
                }
            }
            .frame(width: 11, height: 11)
            Text(text).font(.brand(9.5, weight: .medium)).foregroundStyle(Playful.inkMuted)
        }
    }

    // MARK: - Routine

    private var routineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Rotina de musculação")
            VStack(spacing: 8) {
                ForEach(portfolio.weeklySplit) { day in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(day.day.prefix(3).uppercased())
                                .font(.mono(9.5, weight: .bold))
                                .foregroundStyle(Playful.style(for: "Musculação").deep)
                                .padding(.horizontal, 7).padding(.vertical, 4)
                                .background(Playful.style(for: "Musculação").soft, in: Capsule())
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
                    .background(Playful.canvas.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(18)
        .playfulCard()
    }

    // MARK: - Interests

    private var interestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("O que procura")
            FlowLayout(spacing: 7) {
                ForEach(portfolio.interests, id: \.self) { interest in
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle").font(.system(size: 9))
                        Text(interest).font(.brand(11.5, weight: .semibold))
                    }
                    .foregroundStyle(style.deep)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(style.soft, in: Capsule())
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
                sectionTitle("Avaliações")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 11))
                    Text(portfolio.rating).font(.mono(12, weight: .bold))
                }
                .foregroundStyle(Playful.style(for: "Ciclismo").deep)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(Playful.style(for: "Ciclismo").soft, in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(portfolio.reviews) { review in
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
                                    ForEach(0..<5, id: \.self) { index in
                                        Image(systemName: index < review.rating ? "star.fill" : "star")
                                            .font(.system(size: 8))
                                            .foregroundStyle(Playful.style(for: "Ciclismo").base)
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
                    .background(Playful.canvas.opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(18)
        .playfulCard()
    }

    // MARK: - Invite bar

    private var inviteBar: some View {
        Button(action: onInvite) {
            HStack(spacing: 8) {
                Image(systemName: "hand.wave.fill").font(.system(size: 14, weight: .semibold))
                Text("Convidar \(portfolio.partner.name) pra treinar")
                    .font(.brand(15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .background(
            LinearGradient(colors: [style.base, style.deep], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: style.base.opacity(0.4), radius: 16, y: 8)
        .buttonStyle(.pressable)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.display(14, weight: .semibold))
            .foregroundStyle(Playful.ink)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date()).capitalized
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    private var leadingBlanks: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let firstOfMonth = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstOfMonth) - 1
    }

    private var todayNumber: Int {
        Calendar.current.component(.day, from: Date())
    }
}

#Preview {
    NavigationStack {
        PartnerPortfolioView(
            portfolio: .sample(for: WorkoutPartner.sample[0]),
            onInvite: {}
        )
    }
}
