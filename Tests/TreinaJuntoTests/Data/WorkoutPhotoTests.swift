import Foundation
import Testing
import UIKit
@testable import TreinaJunto

@Suite("Dados · Fotos do treino")
struct WorkoutPhotoRepositoryTests {
    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])

    private func iniciado() async throws -> (InMemoryWorkoutRepository, Workout) {
        let repo = InMemoryWorkoutRepository()
        let treino = try await repo.open(sport: .corrida, gym: nil, maxParticipants: 2, scheduledFor: nil)
        try await repo.start(workoutID: treino.id, usingGymInvites: false)
        return (repo, treino)
    }

    @Test("Foto registrada aparece no treino, com autor")
    func photoIsStored() async throws {
        let (repo, treino) = try await iniciado()

        try await repo.addPhoto(jpeg, to: treino.id)

        let fotos = try await repo.photos(in: treino.id)
        #expect(fotos.count == 1)
        #expect(fotos.first?.authorID == SampleData.meID)
    }

    @Test("Treino aberto ainda não recebe foto")
    func openWorkoutTakesNoPhoto() async throws {
        let repo = InMemoryWorkoutRepository()
        let treino = try await repo.open(sport: .corrida, gym: nil, maxParticipants: 2, scheduledFor: nil)

        await #expect(throws: WorkoutPhotoError.workoutNotStarted) {
            try await repo.addPhoto(jpeg, to: treino.id)
        }
    }

    @Test("Treino encerrado não recebe mais foto")
    func finishedWorkoutTakesNoPhoto() async throws {
        let (repo, treino) = try await iniciado()
        try await repo.finish(workoutID: treino.id, present: [SampleData.meID])

        await #expect(throws: WorkoutPhotoError.workoutNotStarted) {
            try await repo.addPhoto(jpeg, to: treino.id)
        }
    }

    @Test("Quem não está no treino não manda foto")
    func outsiderTakesNoPhoto() async throws {
        var alheio = try Workout(hostID: SampleData.partners[0].id, sport: .corrida)
        try alheio.start()
        let repo = InMemoryWorkoutRepository(workouts: [alheio])

        await #expect(throws: WorkoutPhotoError.notAParticipant) {
            try await repo.addPhoto(jpeg, to: alheio.id)
        }
    }

    @Test("O treino aceita até o limite, e nenhuma a mais")
    func limitPerWorkout() async throws {
        let (repo, treino) = try await iniciado()
        for _ in 0 ..< WorkoutPhoto.limitPerWorkout {
            try await repo.addPhoto(jpeg, to: treino.id)
        }

        await #expect(throws: WorkoutPhotoError.limitReached) {
            try await repo.addPhoto(jpeg, to: treino.id)
        }
    }

    @Test("Imagem vazia é recusada")
    func emptyImageIsRefused() async throws {
        let (repo, treino) = try await iniciado()

        await #expect(throws: WorkoutPhotoError.emptyImage) {
            try await repo.addPhoto(Data(), to: treino.id)
        }
    }
}

@Suite("Fotos · Compressão no aparelho")
struct PhotoCompressorTests {
    private func imagem(largura: CGFloat, altura: CGFloat) -> UIImage {
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: largura, height: altura), format: formato)
            .image { ctx in
                UIColor.orange.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: largura, height: altura))
            }
    }

    @Test("Foto grande encolhe para 1600 no lado maior, mantendo a proporção")
    func largePhotoIsResized() throws {
        let dados = try #require(PhotoCompressor.jpegData(from: imagem(largura: 4032, altura: 3024)))
        let resultado = try #require(UIImage(data: dados))

        #expect(resultado.size.width == 1600)
        #expect(resultado.size.height == 1200)
    }

    @Test("Foto pequena não é ampliada")
    func smallPhotoIsKept() throws {
        let dados = try #require(PhotoCompressor.jpegData(from: imagem(largura: 800, altura: 600)))
        let resultado = try #require(UIImage(data: dados))

        #expect(resultado.size.width == 800)
    }

    @Test("Foto em pé também respeita o lado maior")
    func portraitPhotoIsResized() throws {
        let dados = try #require(PhotoCompressor.jpegData(from: imagem(largura: 3024, altura: 4032)))
        let resultado = try #require(UIImage(data: dados))

        #expect(resultado.size.height == 1600)
    }
}

@MainActor
@Suite("Feed · Fotos do treino")
struct FeedPhotoTests {
    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])

    private func makeModel(_ repo: InMemoryWorkoutRepository) -> FeedViewModel {
        FeedViewModel(
            partnerRepository: InMemoryPartnerRepository(),
            inviteRepository: repo,
            workoutRepository: repo,
            chatRepository: InMemoryChatRepository(),
            photoRepository: repo,
            activity: NoWorkoutActivity()
        )
    }

    @Test("Só dá para registrar foto depois de começar")
    func photoOnlyAfterStart() async {
        let model = makeModel(InMemoryWorkoutRepository())
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        #expect(!model.canAddPhoto)

        await model.startActiveWorkout(usingGymInvites: false)

        #expect(model.canAddPhoto)
    }

    @Test("A foto registrada aparece no card do treino")
    func photoShowsOnCard() async {
        let model = makeModel(InMemoryWorkoutRepository())
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        await model.startActiveWorkout(usingGymInvites: false)

        await model.addPhoto(jpeg)

        #expect(model.activePhotos.count == 1)
        #expect(model.toastMessage == "Foto registrada no treino!")
    }

    @Test("Encerrar tira as fotos do Feed, junto com o treino")
    func finishingClearsPhotos() async {
        let model = makeModel(InMemoryWorkoutRepository())
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        await model.startActiveWorkout(usingGymInvites: false)
        await model.addPhoto(jpeg)

        await model.finishActiveWorkout(present: [SampleData.meID])

        #expect(model.activePhotos.isEmpty)
        #expect(!model.canAddPhoto)
    }
}
