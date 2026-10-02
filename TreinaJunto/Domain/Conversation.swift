import Foundation

enum ConversationKind: String, Codable, Hashable, Sendable {
    /// Duas pessoas que se curtiram. Nasce sozinha, ninguém cria.
    case direct
    /// Criado por alguém, com nome. Entra quem foi chamado ou tem o link.
    case group
}

/// Uma conversa na aba Chat.
///
/// É entre pessoas, não de um treino (docs/PRODUTO.md §9). O treino é o que
/// se combina dentro dela — por isso a mesma conversa serve para o treino de
/// hoje e para o da semana que vem.
struct Conversation: Identifiable, Hashable, Sendable {
    let id: UUID
    let kind: ConversationKind
    /// Só grupo tem nome. Na privada, o nome é o da outra pessoa.
    let name: String?
    let createdBy: UUID?
    let createdAt: Date

    private(set) var memberIDs: [UUID]

    /// A conversa privada que nasce de uma curtida mútua.
    static func direct(between first: UUID, and second: UUID, now: Date = Date()) throws -> Conversation {
        guard first != second else { throw ConversationError.cannotTalkToYourself }
        return Conversation(
            id: UUID(),
            kind: .direct,
            name: nil,
            createdBy: nil,
            createdAt: now,
            memberIDs: [first, second]
        )
    }

    /// Um grupo. Quem cria já entra; os outros chegam pelo convite.
    static func group(
        named name: String,
        createdBy creatorID: UUID,
        members: [UUID],
        now: Date = Date()
    ) throws -> Conversation {
        let limpo = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpo.isEmpty else { throw ConversationError.groupNeedsAName }

        var membros = [creatorID]
        for id in members where !membros.contains(id) {
            membros.append(id)
        }
        return Conversation(
            id: UUID(),
            kind: .group,
            name: limpo,
            createdBy: creatorID,
            createdAt: now,
            memberIDs: membros
        )
    }

    func contains(_ profileID: UUID) -> Bool {
        memberIDs.contains(profileID)
    }

    /// Na privada, quem está do outro lado.
    func otherMember(than profileID: UUID) -> UUID? {
        guard kind == .direct else { return nil }
        return memberIDs.first { $0 != profileID }
    }

    /// Alguém entra no grupo. Conversa privada é sempre de duas pessoas —
    /// pôr uma terceira nela seria mostrar a ela o que não foi dito para ela.
    mutating func add(_ profileID: UUID) throws {
        guard kind == .group else { throw ConversationError.directIsAlwaysTwo }
        guard !contains(profileID) else { throw ConversationError.alreadyMember }
        memberIDs.append(profileID)
    }
}

enum ConversationError: Error, Equatable {
    case cannotTalkToYourself
    case groupNeedsAName
    case directIsAlwaysTwo
    case alreadyMember
    case notAMember
    case conversationNotFound
    /// Chamar para o grupo alguém com quem não tenho conversa. Sem curtida
    /// mútua, o único caminho é o link.
    case notInMyConversations
    case emptyMessage
    case linkNotFound
    case linkExpired
    case linkRevoked
    /// Só quem criou o grupo gera e revoga link.
    case notGroupCreator
}
