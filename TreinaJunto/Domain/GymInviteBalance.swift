import Foundation

/// Quantos convites de academia a pessoa ainda tem no ciclo atual.
///
/// O saldo é **calculado**, nunca guardado. A cota do plano e a data de cada
/// uso é que ficam gravadas — assim a virada do mês zera sozinha, sem tarefa
/// agendada que possa falhar calada e deixar alguém sem convite.
struct GymInviteBalance: Hashable, Sendable {
    /// Quantos convites o plano dá por mês.
    let perMonth: Int
    /// Quando cada convite foi usado.
    let uses: [Date]

    init(perMonth: Int, uses: [Date] = []) {
        self.perMonth = perMonth
        self.uses = uses
    }

    /// Quem não tem convite no plano não deve nem ser perguntado.
    var hasInvites: Bool {
        perMonth > 0
    }

    func usedThisMonth(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let inicioDoMes = calendar.dateInterval(of: .month, for: now)?.start else {
            return uses.count
        }
        return uses.count { $0 >= inicioDoMes }
    }

    func available(now: Date = Date(), calendar: Calendar = .current) -> Int {
        max(0, perMonth - usedThisMonth(now: now, calendar: calendar))
    }
}
