import Foundation
import SwiftData

/// Monta o banco do perfil.
///
/// O SwiftData grava em `Library/Application Support/` por padrão — pasta que
/// **não existe** num container recém-criado, e que ele não cria sozinho. Sem
/// isto, a primeira abertura do app falhava ao criar o arquivo e a
/// persistência caía num fallback em memória, silenciosamente: o app
/// funcionava, mas o perfil sumia ao fechar.
enum ProfileStore {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(
                for: StoredProfile.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        let url = try storeURL()
        return try ModelContainer(
            for: StoredProfile.self,
            configurations: ModelConfiguration(url: url)
        )
    }

    private static func storeURL() throws -> URL {
        let fileManager = FileManager.default
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        // `create: true` acima já cria a pasta, mas deixamos explícito para o
        // caso de o diretório existir como arquivo quebrado.
        if !fileManager.fileExists(atPath: support.path) {
            try fileManager.createDirectory(at: support, withIntermediateDirectories: true)
        }
        return support.appending(path: "TreinaJunto.store")
    }
}
