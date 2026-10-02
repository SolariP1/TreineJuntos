import Foundation

/// As fotos de cada treino.
///
/// Vive no mesmo ator dos treinos, como os convites: quem pode mandar foto
/// depende de quem está no treino e de em que pé ele está, e as duas coisas
/// precisam ser lidas juntas.
protocol WorkoutPhotoRepository: Sendable {
    /// Registro uma foto no treino. A imagem já chega comprimida.
    @discardableResult
    func addPhoto(_ jpegData: Data, to workoutID: UUID) async throws -> WorkoutPhoto

    /// As fotos de um treino, da mais antiga para a mais nova.
    func photos(in workoutID: UUID) async throws -> [WorkoutPhoto]
}
