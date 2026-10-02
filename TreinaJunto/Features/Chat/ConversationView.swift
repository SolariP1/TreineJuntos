import SwiftUI

/// Uma conversa aberta: as mensagens e o campo de escrever.
struct ConversationView: View {
    let summary: ConversationSummary

    @Environment(\.dependencies) private var dependencies
    @State private var model: ConversationViewModel?
    @FocusState private var typing: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Playful.canvas.ignoresSafeArea()

            if let model {
                VStack(spacing: 0) {
                    messages(model)
                    composer(model)
                }

                if let message = model.toastMessage {
                    ToastView(message: message)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle(summary.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if let model, model.canManageLink {
                ToolbarItem(placement: .topBarTrailing) { linkMenu(model) }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model?.toastMessage)
        .task {
            if model == nil {
                model = ConversationViewModel(
                    summary: summary,
                    repository: dependencies.chat,
                    invites: dependencies.invites,
                    workouts: dependencies.workouts
                )
            }
            await model?.load()
        }
    }

    // MARK: - Mensagens

    private func messages(_ model: ConversationViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(model.messages) { mensagem in
                        MessageBubble(
                            message: mensagem,
                            isMine: model.isMine(mensagem),
                            authorName: summary.isGroup ? summary.author(of: mensagem)?.name : nil,
                            workoutCard: workoutCard(for: mensagem, in: model),
                            onRespond: { aceito in
                                guard case let .workoutInvite(id) = mensagem.content else { return }
                                Task { await model.respond(toWorkout: id, accepted: aceito) }
                            }
                        )
                        .id(mensagem.id)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            .onChange(of: model.messages.last?.id) { _, ultima in
                guard let ultima else { return }
                withAnimation { proxy.scrollTo(ultima, anchor: .bottom) }
            }
        }
    }

    private func workoutCard(
        for message: ChatMessage,
        in model: ConversationViewModel
    ) -> ConversationViewModel.WorkoutCard? {
        guard case let .workoutInvite(id) = message.content else { return nil }
        return model.workoutCards[id]
    }

    private func composer(_ model: ConversationViewModel) -> some View {
        HStack(spacing: 10) {
            TextField("Mensagem", text: Bindable(model).draft, axis: .vertical)
                .font(.brand(14))
                .lineLimit(1 ... 5)
                .focused($typing)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Playful.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .submitLabel(.send)
                .onSubmit { Task { await model.send() } }

            Button {
                Task { await model.send() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        model.canSend ? Palette.accent.base : Playful.inkFaint,
                        in: Circle()
                    )
            }
            .buttonStyle(.pressable)
            .disabled(!model.canSend)
            .accessibilityLabel("Enviar")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Playful.canvas)
    }

    // MARK: - Link do grupo

    private func linkMenu(_ model: ConversationViewModel) -> some View {
        Menu {
            if let url = model.inviteLink?.url {
                ShareLink(
                    item: url,
                    subject: Text(summary.title),
                    message: Text("Entra no grupo \(summary.title) no TreinaJunto")
                ) {
                    Label("Compartilhar link", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    Task { await model.revokeInviteLink() }
                } label: {
                    Label("Desativar link", systemImage: "link.badge.plus")
                }
            } else {
                Button {
                    Task { await model.createInviteLink() }
                } label: {
                    Label("Gerar link de convite", systemImage: "link")
                }
            }
        } label: {
            Image(systemName: "person.badge.plus")
        }
        .accessibilityLabel("Convidar para o grupo")
    }
}
