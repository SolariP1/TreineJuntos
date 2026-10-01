import SwiftUI

/// A aba Chat: as conversas privadas e os grupos.
struct ChatListView: View {
    @Environment(\.dependencies) private var dependencies

    /// Token de um link de grupo aberto de fora do app. A aba consome e
    /// limpa, para o mesmo link não abrir a prévia duas vezes.
    @Binding var pendingGroupToken: String?

    @State private var model: ChatListViewModel?
    @State private var path: [ConversationSummary] = []
    @State private var showCreateGroup = false
    @State private var previewToken: String?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Playful.canvas.ignoresSafeArea()

                if let model {
                    content(model)

                    if let message = model.toastMessage {
                        ToastView(message: message)
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ConversationSummary.self) { resumo in
                ConversationView(summary: resumo)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model?.toastMessage)
        .sheet(isPresented: $showCreateGroup) {
            if let model {
                CreateGroupSheet(contacts: model.contacts) { nome, membros in
                    Task {
                        if let grupo = await model.createGroup(named: nome, with: membros) {
                            path = [grupo]
                        }
                    }
                }
            }
        }
        .sheet(item: groupPreviewBinding) { resumo in
            JoinGroupSheet(summary: resumo) {
                guard let token = previewToken else { return }
                Task {
                    if let grupo = await model?.joinPreviewedGroup(token: token) {
                        path = [grupo]
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            if model == nil {
                model = ChatListViewModel(repository: dependencies.chat)
            }
            await model?.load()
            await consumePendingToken()
        }
        .onChange(of: pendingGroupToken) {
            Task { await consumePendingToken() }
        }
        .onChange(of: path) { _, novo in
            // Voltando de uma conversa: a última mensagem e a ordem da lista
            // mudaram enquanto ela estava aberta.
            if novo.isEmpty {
                Task { await model?.load() }
            }
        }
    }

    private var groupPreviewBinding: Binding<ConversationSummary?> {
        Binding(
            get: { model?.groupPreview },
            set: { model?.groupPreview = $0 }
        )
    }

    private func consumePendingToken() async {
        guard let token = pendingGroupToken, let model else { return }
        pendingGroupToken = nil
        previewToken = token
        // Volta para a lista: a prévia e os avisos moram nela, e ficariam
        // escondidos atrás de uma conversa aberta.
        path = []
        await model.openInviteLink(token: token)
    }

    @ViewBuilder
    private func content(_ model: ChatListViewModel) -> some View {
        switch model.conversations {
        case .idle, .loading:
            ProgressView().controlSize(.large).tint(Palette.accent.base)

        case let .failed(message):
            VStack(spacing: 12) {
                Text(message)
                    .font(.brand(13))
                    .foregroundStyle(Playful.inkMuted)
                    .multilineTextAlignment(.center)
                Button("Tentar de novo") { Task { await model.load() } }
                    .font(.brand(13, weight: .bold))
                    .tint(Palette.accent.base)
            }
            .padding(32)

        case let .loaded(conversas):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if conversas.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(conversas) { resumo in
                                NavigationLink(value: resumo) {
                                    ConversationRow(summary: resumo)
                                }
                                .buttonStyle(.pressable)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            .refreshable { await model.load() }
        }
    }

    private var header: some View {
        HStack {
            Text("Conversas")
                .font(.display(24, weight: .bold))
                .foregroundStyle(Playful.ink)
            Spacer()
            CircleIconButton(symbol: "person.2.badge.plus") { showCreateGroup = true }
                .accessibilityLabel("Criar grupo")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            MascotView(color: Palette.sky.base, deepColor: Palette.sky.deep, size: 100, mood: .sleepy)
            Text("Nenhuma conversa ainda")
                .font(.display(16, weight: .semibold))
                .foregroundStyle(Playful.ink)
            Text("Quando você e alguém se curtirem, a conversa aparece aqui.")
                .font(.brand(12.5))
                .foregroundStyle(Playful.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 30)
    }
}

#Preview {
    ChatListView(pendingGroupToken: .constant(nil))
}
