import Foundation
import Testing
@testable import TreinaJunto

@Suite("Domínio · Saldo de convites")
struct GymInviteBalanceTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .gmt
        return calendar
    }

    private func data(_ ano: Int, _ mes: Int, _ dia: Int) -> Date {
        calendar.date(from: DateComponents(year: ano, month: mes, day: dia, hour: 12)) ?? Date()
    }

    @Test("Plano sem convite não tem por que perguntar nada")
    func noInvitesMeansNoQuestion() {
        #expect(GymInviteBalance(perMonth: 0).hasInvites == false)
        #expect(GymInviteBalance(perMonth: 3).hasInvites == true)
    }

    @Test("Sem uso, o saldo é a cota inteira")
    func unusedBalanceIsTheWholeQuota() {
        let saldo = GymInviteBalance(perMonth: 4)
        #expect(saldo.available(now: data(2026, 9, 27), calendar: calendar) == 4)
    }

    @Test("Cada uso no mês desconta um")
    func eachUseThisMonthSubtractsOne() {
        let saldo = GymInviteBalance(
            perMonth: 4,
            uses: [data(2026, 9, 3), data(2026, 9, 14)]
        )

        #expect(saldo.available(now: data(2026, 9, 27), calendar: calendar) == 2)
    }

    @Test("O saldo zera na virada do mês, sem nada rodar")
    func balanceResetsOnMonthChange() {
        // É a razão de o saldo ser calculado em vez de guardado: não existe
        // tarefa agendada que possa falhar e deixar alguém sem convite.
        let saldo = GymInviteBalance(
            perMonth: 2,
            uses: [data(2026, 9, 10), data(2026, 9, 20)]
        )

        #expect(saldo.available(now: data(2026, 9, 30), calendar: calendar) == 0)
        #expect(saldo.available(now: data(2026, 10, 1), calendar: calendar) == 2)
    }

    @Test("Uso do mês passado não conta no atual")
    func lastMonthUsesDoNotCount() {
        let saldo = GymInviteBalance(
            perMonth: 3,
            uses: [data(2026, 8, 28), data(2026, 8, 30), data(2026, 9, 2)]
        )

        #expect(saldo.available(now: data(2026, 9, 15), calendar: calendar) == 2)
    }

    @Test("Saldo nunca fica negativo, mesmo se a cota do plano diminuir")
    func balanceNeverGoesNegative() {
        // Quem baixa de plano no meio do mês depois de usar tudo não deve ver
        // um número negativo na tela.
        let saldo = GymInviteBalance(
            perMonth: 1,
            uses: [data(2026, 9, 3), data(2026, 9, 5), data(2026, 9, 9)]
        )

        #expect(saldo.available(now: data(2026, 9, 27), calendar: calendar) == 0)
    }
}
