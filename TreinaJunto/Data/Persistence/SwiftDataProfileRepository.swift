import Foundation
import SwiftData

/// O perfil como o SwiftData guarda.
///
/// É um tipo separado do `UserProfile` de propósito: o domínio não deve
/// depender de SwiftData, do mesmo jeito que não depende de SwiftUI. Este
/// aqui é detalhe de armazenamento e pode mudar de forma sem arrastar o
/// resto do app junto.
@Model
final class StoredProfile {
    /// Sempre um só registro por aparelho, identificado pela sessão.
    @Attribute(.unique) var userID: UUID
    var name: String
    var city: String
    var bio: String
    var trainings: Int
    var partners: Int
    var rating: String
    var sportsRaw: [String]
    var trainingInterests: [String]
    @Attribute(.externalStorage) var photos: [Data]
    var weeklySplitData: Data
    var reviewsData: Data

    init(userID: UUID, profile: UserProfile) {
        self.userID = userID
        name = profile.name
        city = profile.city
        bio = profile.bio
        trainings = profile.trainings
        partners = profile.partners
        rating = profile.rating
        sportsRaw = profile.sports.map(\.rawValue)
        trainingInterests = profile.trainingInterests
        photos = profile.photos
        weeklySplitData = (try? JSONEncoder().encode(profile.weeklySplit)) ?? Data()
        reviewsData = (try? JSONEncoder().encode(profile.reviews)) ?? Data()
    }

    func apply(_ profile: UserProfile) {
        name = profile.name
        city = profile.city
        bio = profile.bio
        trainings = profile.trainings
        partners = profile.partners
        rating = profile.rating
        sportsRaw = profile.sports.map(\.rawValue)
        trainingInterests = profile.trainingInterests
        photos = profile.photos
        weeklySplitData = (try? JSONEncoder().encode(profile.weeklySplit)) ?? Data()
        reviewsData = (try? JSONEncoder().encode(profile.reviews)) ?? Data()
    }

    var asDomain: UserProfile {
        UserProfile(
            name: name,
            city: city,
            bio: bio,
            trainings: trainings,
            partners: partners,
            rating: rating,
            // Um esporte que o app não conhece mais é ignorado, não quebra
            // o perfil inteiro.
            sports: sportsRaw.compactMap(Sport.init(rawValue:)),
            trainingInterests: trainingInterests,
            photos: photos,
            weeklySplit: (try? JSONDecoder().decode([WorkoutDay].self, from: weeklySplitData)) ?? [],
            reviews: (try? JSONDecoder().decode([Review].self, from: reviewsData)) ?? []
        )
    }
}

/// Perfil gravado em disco, que sobrevive a fechar o app.
@ModelActor
actor SwiftDataProfileRepository: ProfileRepository {
    /// Dono do perfil neste aparelho. Com autenticação de verdade vem da
    /// sessão; por enquanto é fixo para haver sempre um registro só.
    private var userID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    }

    func currentProfile() async throws -> UserProfile {
        if let stored = try fetchStored() {
            return stored.asDomain
        }
        // Primeira abertura: semeia com o perfil de exemplo, para a tela não
        // nascer vazia enquanto o onboarding ainda não coleta nada.
        let seed = SampleData.profile
        modelContext.insert(StoredProfile(userID: userID, profile: seed))
        try modelContext.save()
        return seed
    }

    func save(_ profile: UserProfile) async throws {
        if let stored = try fetchStored() {
            stored.apply(profile)
        } else {
            modelContext.insert(StoredProfile(userID: userID, profile: profile))
        }
        try modelContext.save()
    }

    private func fetchStored() throws -> StoredProfile? {
        let dono = userID
        let descriptor = FetchDescriptor<StoredProfile>(
            predicate: #Predicate { $0.userID == dono }
        )
        return try modelContext.fetch(descriptor).first
    }
}
