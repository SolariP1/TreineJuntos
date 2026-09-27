import SwiftUI

/// O calendário do mês: um círculo por dia, cheio quando treinou junto,
/// tracejado quando abriu treino e ninguém foi.
struct TrainingCalendarCard: View {
    let days: [Int: TrainingDayState]
    let dayPartners: [Int: String]
    let style: SportStyle
    let appeared: Bool

    @State private var selectedDay: Int?

    private let layout = MonthLayout(containing: Date())
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionTitle("Histórico de treinos")
                Spacer()
                Text(monthName)
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(Playful.inkMuted)
            }

            weekdayHeader

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0 ..< layout.leadingBlanks, id: \.self) { index in
                    Color.clear.frame(height: 38).id("blank\(index)")
                }
                ForEach(1 ... layout.dayCount, id: \.self) { day in
                    dayCell(day)
                }
            }

            legend
        }
        .padding(18)
        .playfulCard(Playful.surface, tint: style.base)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(["D", "S", "T", "Q", "Q", "S", "S"].enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.brand(10, weight: .bold))
                    .foregroundStyle(Playful.inkFaint)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let state = days[day] ?? .idle
        let isToday = day == layout.today
        let isSelected = selectedDay == day

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                selectedDay = isSelected ? nil : day
            }
        } label: {
            ZStack {
                switch state {
                case .trainedTogether:
                    Circle().fill(style.base)
                case .openedAlone:
                    Circle()
                        .strokeBorder(
                            style.base.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.6, dash: [3, 3])
                        )
                case .idle:
                    Circle().fill(Playful.canvas)
                }

                Text("\(day)")
                    .font(.mono(11, weight: state == .trainedTogether ? .bold : .medium))
                    .foregroundStyle(textColor(for: state))

                if state == .trainedTogether, let initial = dayPartners[day] {
                    Text(initial)
                        .font(.brand(7.5, weight: .bold))
                        .foregroundStyle(style.deep)
                        .frame(width: 14, height: 14)
                        .background(.white, in: Circle())
                        .offset(x: 12, y: -12)
                }
            }
            .frame(height: 38)
            .overlay(
                Circle()
                    .stroke(Playful.ink.opacity(isToday ? 0.5 : 0), lineWidth: 1.5)
                    .padding(-3)
            )
            .scaleEffect(isSelected ? 1.16 : 1)
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.7).delay(Double(day) * 0.012 + 0.2),
                value: appeared
            )
        }
        .buttonStyle(.plain)
    }

    private func textColor(for state: TrainingDayState) -> Color {
        switch state {
        case .trainedTogether: .white
        case .openedAlone: style.deep
        case .idle: Playful.inkFaint
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(fill: true, text: "Treinou junto")
            legendItem(fill: false, text: "Abriu, sem parceiro")
            HStack(spacing: 5) {
                Circle().fill(Playful.canvas).frame(width: 11, height: 11)
                Text("Sem treino")
                    .font(.brand(9.5, weight: .medium))
                    .foregroundStyle(Playful.inkMuted)
            }
        }
        .padding(.top, 2)
    }

    private func legendItem(fill: Bool, text: String) -> some View {
        HStack(spacing: 5) {
            Group {
                if fill {
                    Circle().fill(style.base)
                } else {
                    Circle().strokeBorder(
                        style.base.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.4, dash: [2.5, 2.5])
                    )
                }
            }
            .frame(width: 11, height: 11)
            Text(text).font(.brand(9.5, weight: .medium)).foregroundStyle(Playful.inkMuted)
        }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date()).capitalized
    }
}
