/// O perfil de quem está usando o app.
protocol ProfileRepository: Sendable {
    func currentProfile() async throws -> UserProfile
    func save(_ profile: UserProfile) async throws
}
