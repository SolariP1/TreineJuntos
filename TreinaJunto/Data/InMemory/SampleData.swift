import Foundation

/// Dados de exemplo que sustentam o app enquanto não existe servidor.
///
/// Ficam aqui, e não dentro dos tipos de `Domain`, para que o dublê e o
/// modelo real nunca morem no mesmo arquivo. Na fase 4 isto vira a
/// implementação em memória dos repositórios; quando a API chegar, some.
enum SampleData {
    static let partners: [WorkoutPartner] = [
        WorkoutPartner(name: "Marina", age: 27, sport: .corrida, distanceInMeters: 450, gradientIndex: 0),
        WorkoutPartner(name: "Lucas", age: 24, sport: .musculacao, distanceInMeters: 800, gradientIndex: 1),
        WorkoutPartner(name: "Beatriz", age: 30, sport: .funcional, distanceInMeters: 1200, gradientIndex: 2),
        WorkoutPartner(name: "Rafael", age: 26, sport: .ciclismo, distanceInMeters: 1500, gradientIndex: 3)
    ]

    static let invites: [IncomingInvite] = [
        IncomingInvite(name: "Camila", sport: .corrida, when: "hoje às 7h", gradientIndex: 2),
        IncomingInvite(name: "Thiago", sport: .funcional, when: "amanhã às 18h", gradientIndex: 3),
        IncomingInvite(name: "Ana", sport: .ciclismo, when: "sábado de manhã", gradientIndex: 0)
    ]

    static let weeklySplit: [WorkoutDay] = [
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

    static let ownReviews: [Review] = [
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

    static let profile = UserProfile(
        name: "Lucas Almeida",
        city: "Goiânia, GO",
        bio: "Treino corrida de manhã cedo antes do trabalho. "
            + "Procurando parceiros pra correr e treinar funcional junto.",
        trainings: 23,
        partners: 12,
        rating: "4.9",
        sports: [.corrida, .funcional, .musculacao],
        trainingInterests: [
            "Treino matinal", "Parceiro fixo", "Nível intermediário", "Foco em hipertrofia"
        ],
        photos: [],
        weeklySplit: weeklySplit,
        reviews: ownReviews
    )
}
