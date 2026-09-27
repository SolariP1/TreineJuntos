import SwiftUI

struct MainTabView: View {
    var onLogout: () -> Void

    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "flame.fill") }

            PlaceholderView(
                mood: .happy,
                sport: "Funcional",
                title: "Busca por esporte",
                message: "Filtre por modalidade, horário e distância. Chegando em breve."
            )
            .tabItem { Label("Buscar", systemImage: "magnifyingglass") }

            PlaceholderView(
                mood: .sleepy,
                sport: "Natação",
                title: "Nenhuma conversa ainda",
                message: "Convide alguém no Feed — quando aceitar, a conversa aparece aqui."
            )
            .tabItem { Label("Chat", systemImage: "bubble.left.fill") }

            ProfileView(onLogout: onLogout)
                .tabItem { Label("Perfil", systemImage: "person.fill") }
        }
        .tint(Playful.style(for: "Corrida").base)
    }
}

struct PlaceholderView: View {
    let mood: MascotView.Mood
    let sport: String
    let title: String
    let message: String

    private var style: SportStyle { Playful.style(for: sport) }

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
