import Foundation

extension SampleData {
    /// Portfólio sintético e determinístico: o mesmo parceiro sempre gera os
    /// mesmos números entre execuções, para a tela não piscar valores novos
    /// a cada abertura.
    static func portfolio(for partner: WorkoutPartner) -> PartnerPortfolio {
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
            weeklySplit: weeklySplit,
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
