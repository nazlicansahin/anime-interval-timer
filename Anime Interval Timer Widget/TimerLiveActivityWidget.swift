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
                    Text(format(seconds: context.state.remainingSeconds))
                        .font(.title2.monospacedDigit().bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.phaseTitle)
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(Color(red: 0.59, green: 0.42, blue: 0.60))
            } compactTrailing: {
                Text(format(seconds: context.state.remainingSeconds))
                    .font(.caption.monospacedDigit().bold())
            } minimal: {
                Text(format(seconds: context.state.remainingSeconds))
                    .font(.caption2.monospacedDigit().bold())
            }
        }
    }

    private func format(seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
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
            Text(format(seconds: context.state.remainingSeconds))
                .font(.title.monospacedDigit().bold())
                .foregroundStyle(Color(red: 0.59, green: 0.42, blue: 0.60))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func format(seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
