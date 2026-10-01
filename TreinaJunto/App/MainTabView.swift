import SwiftUI

struct MainTabView: View {
    var onLogout: () -> Void

    private enum Tab: Hashable {
        case feed, search, chat, profile
    }

    @State private var tab: Tab = .feed
    /// Link de grupo aberto de fora do app, esperando a aba Chat consumir.
    @State private var pendingGroupToken: String?

    var body: some View {
        TabView(selection: $tab) {
            FeedView()
                .tabItem { Label("Feed", systemImage: "flame.fill") }
                .tag(Tab.feed)

            PlaceholderView(
                mood: .happy,
                sport: .funcional,
                title: "Busca por esporte",
                message: "Filtre por modalidade, horário e distância. Chegando em breve."
            )
            .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
            .tag(Tab.search)

            ChatListView(pendingGroupToken: $pendingGroupToken)
                .tabItem { Label("Chat", systemImage: "bubble.left.fill") }
                .tag(Tab.chat)

            ProfileView(onLogout: onLogout)
                .tabItem { Label("Perfil", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
        .tint(Palette.accent.base)
        .onOpenURL { url in
            // treinajunto://grupo/<token>
            guard url.scheme == "treinajunto", url.host() == "grupo", let token = url.pathComponents.last,
                  token != "/"
            else { return }
            tab = .chat
            pendingGroupToken = token
        }
    }
}

struct PlaceholderView: View {
    let mood: MascotView.Mood
    let sport: Sport
    let title: String
    let message: String

    private var style: SportStyle {
        sport.style
    }

    var body: some View {
        ZStack {
            Playful.canvas.ignoresSafeArea()

            VStack(spacing: 16) {
                MascotView(color: style.base, deepColor: style.deep, size: 110, mood: mood)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.display(17, weight: .semibold))
                        .foregroundStyle(Playful.ink)
                    Text(message)
                        .font(.brand(12.5))
                        .foregroundStyle(Playful.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 44)
                }
            }
        }
    }
}

#Preview {
    MainTabView(onLogout: {})
}
