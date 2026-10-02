import ActivityKit
import SwiftUI
import WidgetKit

/// A Live Activity do treino: tela bloqueada e Dynamic Island, como o iFood
/// mostra o pedido (docs/PRODUTO.md §9.4).
///
/// O relógio usa `Text(timerInterval:)`: quem conta é o sistema, a partir de
/// `startedAt`, sem o app acordar e sem push.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let tint = context.attributes.tint
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.sportName, systemImage: context.attributes.sportSymbol)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(tint)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ElapsedTime(state: context.state)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Faces(initials: context.state.participantInitials, tint: tint, size: 26)
                        Spacer()
                        if let lugar = context.attributes.place {
                            Text(lugar)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: context.attributes.sportSymbol)
                    .foregroundStyle(tint)
            } compactTrailing: {
                ElapsedTime(state: context.state)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: context.attributes.sportSymbol)
                    .foregroundStyle(tint)
            }
            .widgetURL(URL(string: "treinajunto://treino"))
            .keylineTint(tint)
        }
    }
}

/// O tempo do treino. Correndo enquanto dura; parado no total ao encerrar.
private struct ElapsedTime: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if let fim = state.finishedAt {
            Text(
                Duration.seconds(fim.timeIntervalSince(state.startedAt)),
                format: .time(pattern: .minuteSecond)
            )
            .monospacedDigit()
        } else {
            Text(timerInterval: state.startedAt ... .distantFuture, countsDown: false)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct Faces: View {
    let initials: [String]
    let tint: Color
    var size: CGFloat

    var body: some View {
        HStack(spacing: -size * 0.25) {
            ForEach(Array(initials.prefix(6).enumerated()), id: \.offset) { _, inicial in
                Text(inicial)
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(tint, in: Circle())
                    .overlay(Circle().stroke(.black, lineWidth: 2))
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        let tint = context.attributes.tint
        HStack(spacing: 14) {
            Image(systemName: context.attributes.sportSymbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(tint, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(context.state.finishedAt == nil ? "Treinando agora" : "Treino encerrado")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(context.attributes.sportName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Faces(initials: context.state.participantInitials, tint: tint, size: 22)
            }

            Spacer()

            ElapsedTime(state: context.state)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
        .padding(16)
    }
}

extension WorkoutActivityAttributes {
    var tint: Color {
        Color(red: tintRed, green: tintGreen, blue: tintBlue)
    }
}
