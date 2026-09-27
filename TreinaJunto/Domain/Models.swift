import SwiftUI

struct WorkoutPartner: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let age: Int
    let sport: Sport
    let distance: String
    let gradientIndex: Int

    var initials: String {
        String(name.prefix(1))
    }

    var gradient: LinearGradient {
        Theme.avatarGradients[gradientIndex % Theme.avatarGradients.count]
    }
}

extension WorkoutPartner {
    static let sample: [WorkoutPartner] = [
        WorkoutPartner(name: "Marina", age: 27, sport: .corrida, distance: "450m", gradientIndex: 0),
        WorkoutPartner(name: "Lucas", age: 24, sport: .musculacao, distance: "800m", gradientIndex: 1),
        WorkoutPartner(name: "Beatriz", age: 30, sport: .funcional, distance: "1.2km", gradientIndex: 2),
        WorkoutPartner(name: "Rafael", age: 26, sport: .ciclismo, distance: "1.5km", gradientIndex: 3)
    ]
}

struct IncomingInvite: Identifiable {
    let id = UUID()
    let name: String
    let sport: Sport
    let when: String
    let gradientIndex: Int

    var initials: String {
        String(name.prefix(1))
    }

    var gradient: LinearGradient {
        Theme.avatarGradients[gradientIndex % Theme.avatarGradients.count]
    }
}

extension IncomingInvite {
    static let sample: [IncomingInvite] = [
        IncomingInvite(name: "Camila", sport: .corrida, when: "hoje às 7h", gradientIndex: 2),
        IncomingInvite(name: "Thiago", sport: .funcional, when: "amanhã às 18h", gradientIndex: 3),
        IncomingInvite(name: "Ana", sport: .ciclismo, when: "sábado de manhã", gradientIndex: 0)
    ]
}

/// What happened on a given day of someone's training calendar.
enum TrainingDayState {
    /// Nothing was scheduled.
    case idle
    /// They opened a workout but nobody joined.
    case openedAlone
    /// They trained with a partner.
    case trainedTogether
}

/// Everything shown on a partner's public portfolio.
struct PartnerPortfolio: Identifiable {
    let id = UUID()
    let partner: WorkoutPartner
    let bio: String
    /// 0–100 match based on shared sports, schedule and level.
    let compatibility: Int
    let streak: Int
    let totalTrainings: Int
    /// % of opened workouts they actually showed up to.
    let reliability: Int
    let rating: String
    let sports: [Sport]
    let interests: [String]
    let weeklySplit: [WorkoutDay]
    let reviews: [Review]
    /// Day of month → what happened that day.
    let days: [Int: TrainingDayState]
    /// Day of month → who they trained with (initial), when applicable.
    let dayPartners: [Int: String]
}

extension PartnerPortfolio {
    /// Deterministic sample data so each partner always looks the same
    /// between launches — swap for the API once there is a backend.
    static func sample(for partner: WorkoutPartner) -> PartnerPortfolio {
        let seed = partner.name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let partnerInitials = ["L", "M", "R", "B", "C", "T"]

        var days: [Int: TrainingDayState] = [:]
        var dayPartners: [Int: String] = [:]
        for day in 1 ... 31 {
            let roll = (seed &* 37 &+ day &* 23) % 10
            switch roll {
            case 0 ... 3:
                days[day] = .trainedTogether
                dayPartners[day] = partnerInitials[(seed &+ day) % partnerInitials.count]
            case 4 ... 5:
                days[day] = .openedAlone
            default:
                days[day] = .idle
            }
        }

        let trained = days.values.filter { $0 == .trainedTogether }.count
        let opened = days.values.filter { $0 == .openedAlone }.count
        let reliability = opened + trained == 0 ? 100 :
            Int((Double(trained) / Double(trained + opened)) * 100)

        let bios = [
            "Corro cedo antes do trabalho. Ritmo leve, conversa alta.",
            "Treino pesado mas sem pressa — gosto de companhia pra não pular série.",
            "Funcional e corrida no parque. Prefiro treinar de manhã, sempre.",
            "Pedal longo no fim de semana, musculação durante a semana."
        ]

        return PartnerPortfolio(
            partner: partner,
            bio: bios[seed % bios.count],
            compatibility: 70 + (seed % 28),
            streak: 2 + (seed % 12),
            totalTrainings: 14 + (seed % 40),
            reliability: reliability,
            rating: ["4.9", "4.7", "5.0", "4.6"][seed % 4],
            sports: [partner.sport] + (seed % 2 == 0 ? [.funcional] : [.musculacao]),
            interests: [
                ["Treino matinal", "Parceiro fixo", "Nível intermediário"],
                ["Treino noturno", "Foco em resistência", "Grupo/comunidade"],
                ["Parceiro fixo", "Nível avançado", "Foco em hipertrofia"]
            ][seed % 3],
            weeklySplit: UserProfile().weeklySplit,
            reviews: [
                Review(
                    reviewerName: "Marina",
                    rating: 5,
                    comment: "Pontual e animada, treino rendeu demais.",
                    context: "Treinou Corrida",
                    gradientIndex: 0
                ),
                Review(
                    reviewerName: "Thiago",
                    rating: 5,
                    comment: "Me segurou no ritmo quando eu quis parar. Recomendo!",
                    context: "Treinou Funcional",
                    gradientIndex: 1
                ),
                Review(
                    reviewerName: "Beatriz",
                    rating: 4,
                    comment: "Ótima companhia, só atrasou uns minutinhos.",
                    context: "Treinou Musculação",
                    gradientIndex: 2
                )
            ],
            days: days,
            dayPartners: dayPartners
        )
    }
}

let availableInterests = [
    "Treino matinal", "Treino noturno", "Parceiro fixo",
    "Nível iniciante", "Nível intermediário", "Nível avançado",
    "Foco em hipertrofia", "Foco em resistência", "Grupo/comunidade"
]

struct WorkoutDay: Identifiable {
    let id = UUID()
    let day: String
    let focus: String
    let exercises: [String]
}

struct Review: Identifiable {
    let id = UUID()
    let reviewerName: String
    let rating: Int
    let comment: String
    let context: String
    let gradientIndex: Int

    var initials: String {
        String(reviewerName.prefix(1))
    }

    var gradient: LinearGradient {
        Theme.avatarGradients[gradientIndex % Theme.avatarGradients.count]
    }
}

struct UserProfile {
    var name = "Lucas Almeida"
    var city = "Goiânia, GO"
    var bio = "Treino corrida de manhã cedo antes do trabalho. "
        + "Procurando parceiros pra correr e treinar funcional junto."
    var trainings = 23
    var partners = 12
    var rating = "4.9"
    var sports: [Sport] = [.corrida, .funcional, .musculacao]

    var trainingInterests = ["Treino matinal", "Parceiro fixo", "Nível intermediário", "Foco em hipertrofia"]

    /// Locally-picked photo data (from PhotosPicker) — empty until the user adds their own.
    var photos: [Data] = []

    var weeklySplit: [WorkoutDay] = [
        WorkoutDay(
            day: "Segunda",
            focus: "Peito e Tríceps",
            exercises: ["Supino reto", "Supino inclinado", "Crucifixo", "Tríceps corda", "Tríceps testa"]
        ),
        WorkoutDay(
            day: "Terça",
            focus: "Costas e Bíceps",
            exercises: [
                "Puxada frente",
                "Remada curvada",
                "Remada unilateral",
                "Rosca direta",
                "Rosca martelo"
            ]
        ),
        WorkoutDay(
            day: "Quinta",
            focus: "Pernas",
            exercises: [
                "Agachamento livre",
                "Leg press",
                "Cadeira extensora",
                "Mesa flexora",
                "Panturrilha em pé"
            ]
        ),
        WorkoutDay(
            day: "Sexta",
            focus: "Ombro e Abdômen",
            exercises: ["Desenvolvimento", "Elevação lateral", "Encolhimento", "Abdominal supra", "Prancha"]
        )
    ]

    var reviews: [Review] = [
        Review(
            reviewerName: "Marina",
            rating: 5,
            comment: "Treino ótimo, super pontual e animado. Recomendo demais!",
            context: "Treinou Corrida",
            gradientIndex: 0
        ),
        Review(
            reviewerName: "Beatriz",
            rating: 5,
            comment: "Me ajudou bastante com a postura no funcional, parceiro top.",
            context: "Treinou Funcional",
            gradientIndex: 2
        ),
        Review(
            reviewerName: "Rafael",
            rating: 4,
            comment: "Ritmo bom, só chegou uns minutos atrasado.",
            context: "Treinou Ciclismo",
            gradientIndex: 3
        )
    ]
}
