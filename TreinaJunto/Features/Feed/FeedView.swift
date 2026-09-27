import SwiftUI

struct FeedView: View {
    @State private var people = SampleData.partners
    @State private var invites = SampleData.invites
    @State private var invited: Set<UUID> = []
    @State private var toastMessage: String?
    @State private var showAvailabilitySheet = false
    @State private var selectedPartner: WorkoutPartner?
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Playful.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        greeting.sectionEntrance(appeared, index: 0)
                        openWorkoutCard.sectionEntrance(appeared, index: 1)

                        if !invites.isEmpty {
                            inviteSection.sectionEntrance(appeared, index: 2)
                        }

                        nearbySection.sectionEntrance(appeared, index: 3)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    // Clears the floating tab bar so the last card is reachable.
                    .padding(.bottom, 90)
                }

                if let message = toastMessage {
                    ToastView(message: message)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedPartner) { partner in
                PartnerPortfolioView(
                    portfolio: SampleData.portfolio(for: partner),
                    onInvite: {
                        invite(partner)
                        selectedPartner = nil
                    }
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastMessage)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: invites.count)
        .sheet(isPresented: $showAvailabilitySheet) {
            MarkAvailabilitySheet(onPublish: { sport, time in
                toast("Disponibilidade publicada: \(sport) — \(time.lowercased())")
            })
        }
        .onAppear { appeared = true }
    }

    // MARK: - Greeting

    private var greeting: some View {
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
                        if !invites.isEmpty {
                            Text("\(invites.count)")
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

    // MARK: - Hero: open a workout

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
            .background(
                LinearGradient(
                    colors: [style.base, style.deep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: style.base.opacity(0.35), radius: 20, y: 12)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Invites

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text("Convites recebidos")
                    .font(.display(14, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                Text("\(invites.count)")
                    .font(.brand(10.5, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2.5)
                    .background(Palette.accent.base, in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(invites) { invite in
                        InviteCardView(
                            invite: invite,
                            onAccept: { respond(to: invite, accepted: true) },
                            onDecline: { respond(to: invite, accepted: false) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Nearby

    private var nearbySection: some View {
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
                        isInvited: invited.contains(person.id),
                        onInvite: { invite(person) },
                        onOpenProfile: { selectedPartner = person }
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

    // MARK: - Actions

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        // Only the first letter — `.capitalized` would give "Terça-Feira, 22 De Setembro".
        let raw = formatter.string(from: Date())
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    private func invite(_ person: WorkoutPartner) {
        guard !invited.contains(person.id) else { return }
        invited.insert(person.id)
        toast("Convite enviado para \(person.name)!")
    }

    private func respond(to invite: IncomingInvite, accepted: Bool) {
        invites.removeAll { $0.id == invite.id }
        toast(accepted ? "Combinado com \(invite.name)!" : "Convite de \(invite.name) recusado.")
    }

    private func toast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

// MARK: - Invite card

private struct InviteCardView: View {
    let invite: IncomingInvite
    var onAccept: () -> Void
    var onDecline: () -> Void

    private var style: SportStyle {
        invite.sport.style
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                ZStack {
                    Circle().fill(style.gradient)
                    Text(invite.initials).font(.display(14)).foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(invite.name)
                        .font(.brand(13.5, weight: .bold))
                        .foregroundStyle(Playful.ink)
                    HStack(spacing: 4) {
                        Image(systemName: style.symbol).font(.system(size: 8, weight: .semibold))
                        Text(invite.sport.label).font(.brand(9.5, weight: .bold))
                    }
                    .foregroundStyle(style.deep)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.white.opacity(0.75), in: Capsule())
                }
                Spacer(minLength: 0)
            }

            Text(invite.when)
                .font(.brand(11, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .foregroundStyle(Playful.inkMuted)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .buttonStyle(.pressable)

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .foregroundStyle(.white)
                .background(style.base, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .buttonStyle(.pressable)
            }
        }
        .padding(13)
        .frame(width: 196)
        .background(style.soft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: style.base.opacity(0.18), radius: 14, y: 8)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

// MARK: - Person card

private struct PersonCardView: View {
    let person: WorkoutPartner
    let isInvited: Bool
    var onInvite: () -> Void
    var onOpenProfile: () -> Void

    private var style: SportStyle {
        person.sport.style
    }

    var body: some View {
        HStack(spacing: 12) {
            // The identity area opens the portfolio; the invite button stays
            // its own control so the two gestures never fight.
            Button(action: onOpenProfile) {
                HStack(spacing: 12) {
                    ZStack {
                        BlobShape(phase: CGFloat(person.gradientIndex) * 1.1, lobes: 5, amplitude: 0.08)
                            .fill(style.base.opacity(0.3))
                            .frame(width: 58, height: 58)
                        Circle()
                            .fill(style.gradient)
                            .frame(width: 46, height: 46)
                        Text(person.initials)
                            .font(.display(16))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(person.name), \(person.age)")
                            .font(.brand(14.5, weight: .bold))
                            .foregroundStyle(Playful.ink)
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: style.symbol).font(.system(size: 9, weight: .semibold))
                                Text(person.sport.label).font(.brand(10.5, weight: .bold))
                            }
                            .foregroundStyle(style.deep)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(.white.opacity(0.8), in: Capsule())

                            Text(person.distanceLabel)
                                .font(.mono(10.5, weight: .medium))
                                .foregroundStyle(Playful.inkMuted)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)

            Button(action: onInvite) {
                Group {
                    if isInvited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    } else {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(width: 46, height: 46)
            }
            .foregroundStyle(isInvited ? style.deep : .white)
            .background(
                isInvited ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(style.base),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .disabled(isInvited)
            .buttonStyle(.pressable)
        }
        .padding(13)
        .background(style.soft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: style.base.opacity(0.18), radius: 16, y: 8)
    }
}

// MARK: - Toast

private struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Palette.mint.base).frame(width: 7, height: 7)
            Text(message)
                .font(.brand(12.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Playful.ink, in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
    }
}

extension View {
    /// Staggered fade + rise shared by the playful screens.
    func sectionEntrance(_ appeared: Bool, index: Int) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.82).delay(Double(index) * 0.07),
                value: appeared
            )
    }
}

#Preview {
    FeedView()
}
