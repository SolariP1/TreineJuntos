import Foundation
import Testing
@testable import TreinaJunto

@Suite("Domínio · Grade do mês")
struct MonthLayoutTests {
    /// Calendário fixo, para o teste não mudar de resultado conforme o fuso
    /// de quem roda.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .gmt
        return calendar
    }

    private func data(_ ano: Int, _ mes: Int, _ dia: Int) -> Date {
        calendar.date(from: DateComponents(year: ano, month: mes, day: dia)) ?? Date()
    }

    @Test(
        "Cada mês tem o número de dias que deve ter",
        arguments: [
            (2026, 1, 31), (2026, 2, 28), (2026, 4, 30), (2026, 9, 30), (2026, 12, 31)
        ]
    )
    func dayCountPerMonth(ano: Int, mes: Int, esperado: Int) {
        let layout = MonthLayout(containing: data(ano, mes, 1), calendar: calendar)
        #expect(layout.dayCount == esperado)
    }

    @Test("Fevereiro de ano bissexto tem 29 dias")
    func leapFebruaryHas29Days() {
        let layout = MonthLayout(containing: data(2028, 2, 1), calendar: calendar)
        #expect(layout.dayCount == 29)
    }

    @Test("O dia 1 cai na coluna do dia da semana certo")
    func leadingBlanksPlaceTheFirstDay() {
        // 1º de setembro de 2026 é uma terça — domingo e segunda ficam vazios.
        let layout = MonthLayout(containing: data(2026, 9, 15), calendar: calendar)
        #expect(layout.leadingBlanks == 2)
    }

    @Test("Mês que começa no domingo não tem célula vazia")
    func monthStartingOnSundayHasNoBlanks() {
        // 1º de fevereiro de 2026 é um domingo.
        let layout = MonthLayout(containing: data(2026, 2, 10), calendar: calendar)
        #expect(layout.leadingBlanks == 0)
    }

    @Test("A grade nunca passa de seis semanas")
    func gridNeverExceedsSixWeeks() {
        // Se passasse, a grade quebraria o layout do card.
        for mes in 1 ... 12 {
            let layout = MonthLayout(containing: data(2026, mes, 1), calendar: calendar)
            #expect(layout.cellCount <= 42, "mês \(mes) precisou de \(layout.cellCount) células")
        }
    }

    @Test("Um mês que não é o atual não marca nenhum dia como hoje")
    func otherMonthsHaveNoToday() {
        let layout = MonthLayout(containing: data(2020, 3, 15), calendar: calendar)
        #expect(layout.today == nil)
    }
}
