import Foundation

/// As contas de um mês para desenhar a grade do calendário.
///
/// Saiu da View porque é aritmética pura de calendário — o tipo de coisa que
/// erra em virada de mês e em fuso, e que ninguém descobre olhando a tela.
struct MonthLayout: Equatable {
    /// Quantos dias o mês tem.
    let dayCount: Int
    /// Quantas células vazias antes do dia 1, para ele cair no dia da semana
    /// certo numa grade que começa no domingo.
    let leadingBlanks: Int
    /// O dia de hoje, quando hoje está dentro deste mês.
    let today: Int?

    init(containing date: Date, calendar: Calendar = .current) {
        dayCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 30

        let components = calendar.dateComponents([.year, .month], from: date)
        if let firstOfMonth = calendar.date(from: components) {
            leadingBlanks = calendar.component(.weekday, from: firstOfMonth) - 1
        } else {
            leadingBlanks = 0
        }

        today = calendar.isDate(date, equalTo: Date(), toGranularity: .month)
            ? calendar.component(.day, from: date)
            : nil
    }

    /// Total de células da grade, contando os vazios do começo.
    var cellCount: Int {
        leadingBlanks + dayCount
    }
}
