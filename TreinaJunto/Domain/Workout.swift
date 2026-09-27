import Foundation

/// Em que pé está um treino.
///
/// São três estados, não dois: abrir e iniciar são momentos diferentes. Abrir
/// é anunciar que vou treinar e passar a receber convites; iniciar é o treino
/// começando de fato.
enum WorkoutStatus: String, Codable, Hashable, Sendable {
    /// Anunciado, aparece para quem está perto e recebe convites.
    case open
    /// Começou. É quando a Live Activity sobe e o convite de academia é gasto.
    case started
    /// Acabou. É o gancho para confirmar presença e avaliar.
    case finished
    /// Desistiu antes de começar.
    case cancelled
}

/// Um treino: de uma pessoa sozinha esperando companhia até uma party de seis.
///
/// Não é um par. Sempre foi modelado como sessão com participantes, porque
/// tratar dupla como caso especial obrigaria a reescrever tudo no dia da
/// primeira party.
struct Workout: Identifiable, Hashable, Sendable {
    /// Limites de tamanho. Acima de seis o treino vira evento, que é outro
    /// produto — ver docs/PRODUTO.md §2.1.
    static let sizeRange = 2 ... 6

    let id: UUID
    let hostID: UUID
    let sport: Sport
    /// Academia onde vai ser, quando for numa.
    let gym: String?
    let maxParticipants: Int
    let scheduledFor: Date?

    private(set) var status: WorkoutStatus
    private(set) var participants: [WorkoutParticipant]
    private(set) var startedAt: Date?
    private(set) var finishedAt: Date?
    /// Se o anfitrião gastou convites da academia dele neste treino.
    private(set) var usedGymInvites: Int

    /// Abre um treino. O anfitrião já entra como participante — um treino sem
    /// ninguém dentro não faz sentido.
    init(
        id: UUID = UUID(),
        hostID: UUID,
        sport: Sport,
        gym: String? = nil,
        maxParticipants: Int = 2,
        scheduledFor: Date? = nil,
        now: Date = Date()
    ) throws {
        guard Self.sizeRange.contains(maxParticipants) else {
            throw WorkoutError.invalidSize(maxParticipants)
        }
        self.id = id
        self.hostID = hostID
        self.sport = sport
        self.gym = gym
        self.maxParticipants = maxParticipants
        self.scheduledFor = scheduledFor
        status = .open
        participants = [WorkoutParticipant(profileID: hostID, isHost: true, joinedAt: now)]
        startedAt = nil
        finishedAt = nil
        usedGymInvites = 0
    }

    // MARK: - Leitura

    var isParty: Bool {
        maxParticipants > 2
    }

    var isFull: Bool {
        participants.count >= maxParticipants
    }

    var freeSpots: Int {
        max(0, maxParticipants - participants.count)
    }

    /// Quantos participantes não são o anfitrião. É esse número que consome
    /// convite quando o treino é na academia dele.
    var guestCount: Int {
        max(0, participants.count - 1)
    }

    func contains(_ profileID: UUID) -> Bool {
        participants.contains { $0.profileID == profileID }
    }

    // MARK: - Ciclo

    /// Alguém entra no treino. Só enquanto está aberto: depois de começar, a
    /// lista está fechada.
    mutating func join(_ profileID: UUID, now: Date = Date()) throws {
        guard status == .open else { throw WorkoutError.notOpen }
        guard !contains(profileID) else { throw WorkoutError.alreadyJoined }
        guard !isFull else { throw WorkoutError.full }
        participants.append(WorkoutParticipant(profileID: profileID, joinedAt: now))
    }

    /// Alguém desiste antes de começar. O anfitrião não sai do próprio treino
    /// — ele cancela.
    mutating func leave(_ profileID: UUID) throws {
        guard status == .open else { throw WorkoutError.notOpen }
        guard profileID != hostID else { throw WorkoutError.hostCannotLeave }
        guard contains(profileID) else { throw WorkoutError.notAParticipant }
        participants.removeAll { $0.profileID == profileID }
    }

    /// Começa o treino.
    ///
    /// `invitesAvailable` é o saldo do anfitrião. Quando o treino é na
    /// academia dele, cada visitante gasta um convite — e começar com gente a
    /// mais do que cabe no saldo falha aqui, não no portão da academia.
    mutating func start(usingGymInvites: Bool = false, invitesAvailable: Int = 0, now: Date = Date()) throws {
        guard status == .open else {
            throw status == .started ? WorkoutError.alreadyStarted : WorkoutError.notOpen
        }

        if usingGymInvites {
            let necessarios = guestCount
            guard necessarios <= invitesAvailable else {
                throw WorkoutError.notEnoughInvites(needed: necessarios, available: invitesAvailable)
            }
            usedGymInvites = necessarios
        }

        status = .started
        startedAt = now
    }

    /// Encerra o treino, dizendo quem apareceu.
    ///
    /// Quem não for citado conta como ausente: silêncio no fim do treino é
    /// resposta, senão a confiabilidade nunca sairia do lugar.
    mutating func finish(present presentIDs: Set<UUID>, now: Date = Date()) throws {
        guard status == .started else { throw WorkoutError.notStarted }
        participants = participants.map { participante in
            var atualizado = participante
            atualizado.present = presentIDs.contains(participante.profileID)
            return atualizado
        }
        status = .finished
        finishedAt = now
    }

    mutating func cancel() throws {
        guard status == .open else { throw WorkoutError.cannotCancelAfterStart }
        status = .cancelled
    }
}

enum WorkoutError: Error, Equatable {
    /// Fora de 2 a 6.
    case invalidSize(Int)
    case notOpen
    case alreadyStarted
    case notStarted
    case full
    case alreadyJoined
    case notAParticipant
    case hostCannotLeave
    case cannotCancelAfterStart
    /// A party ficou maior do que o saldo de convites do anfitrião permite.
    case notEnoughInvites(needed: Int, available: Int)
    /// Já existe um treino meu de pé. Dois ao mesmo tempo deixariam a Live
    /// Activity sem saber qual mostrar.
    case alreadyHasActiveWorkout
    case workoutNotFound
}
