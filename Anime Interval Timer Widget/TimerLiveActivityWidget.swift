import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.timerTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ActivityCountdownText(
                        state: context.state,
                        font: .title2.bold()
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.phaseTitle)
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(Color(red: 0.59, green: 0.42, blue: 0.60))
            } compactTrailing: {
                ActivityCountdownText(
                    state: context.state,
                    font: .caption.bold()
                )
            } minimal: {
                ActivityCountdownText(
                    state: context.state,
                    font: .caption2.bold()
                )
            }
        }
    }
}

private struct TimerLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.timerTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.phaseTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ActivityCountdownText(
                state: context.state,
                font: .title.bold(),
                color: Color(red: 0.59, green: 0.42, blue: 0.60)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Renders a system-driven countdown while the segment is running. Lock Screen and Dynamic Island advance this text without the app sending an update every second.
private struct ActivityCountdownText: View {
    let state: TimerActivityAttributes.ContentState
    var font: Font
    var color: Color = .primary

    var body: some View {
        Group {
            if let interval = systemInterval {
                Text(
                    timerInterval: interval,
                    countsDown: true,
                    showsHours: interval.upperBound.timeIntervalSince(interval.lowerBound) >= 3600
                )
            } else {
                Text(Self.format(seconds: state.remainingSeconds))
            }
        }
        .font(font.monospacedDigit())
        .foregroundStyle(color)
        .lineLimit(1)
    }

    private var systemInterval: ClosedRange<Date>? {
        guard state.isRunning, let end = state.segmentEndDate, end > Date() else { return nil }
        let start = min(Date(), end.addingTimeInterval(-1))
        guard start < end else { return nil }
        return start...end
    }

    private static func format(seconds: Int) -> String {
        let s = max(0, seconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
