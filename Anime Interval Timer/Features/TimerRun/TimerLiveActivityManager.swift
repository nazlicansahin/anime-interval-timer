import ActivityKit
import Foundation

@MainActor
final class TimerLiveActivityManager {
    private var activity: Activity<TimerActivityAttributes>?

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func sync(
        timerTitle: String,
        phaseTitle: String,
        remainingSeconds: Int,
        segmentEndDate: Date?,
        isRunning: Bool
    ) {
        guard isSupported else { return }
        if activity == nil {
            start(
                timerTitle: timerTitle,
                phaseTitle: phaseTitle,
                remainingSeconds: remainingSeconds,
                segmentEndDate: segmentEndDate,
                isRunning: isRunning
            )
        } else {
            update(
                phaseTitle: phaseTitle,
                remainingSeconds: remainingSeconds,
                segmentEndDate: segmentEndDate,
                isRunning: isRunning
            )
        }
    }

    func start(
        timerTitle: String,
        phaseTitle: String,
        remainingSeconds: Int,
        segmentEndDate: Date?,
        isRunning: Bool
    ) {
        guard isSupported else { return }
        end(immediate: true)

        let attributes = TimerActivityAttributes(timerTitle: timerTitle)
        let state = contentState(
            phaseTitle: phaseTitle,
            remainingSeconds: remainingSeconds,
            segmentEndDate: segmentEndDate,
            isRunning: isRunning
        )
        lastState = state

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: state.segmentEndDate),
                pushType: nil
            )
        } catch {
            activity = nil
            lastState = nil
        }
    }

    func update(
        phaseTitle: String,
        remainingSeconds: Int,
        segmentEndDate: Date?,
        isRunning: Bool
    ) {
        guard let activity else { return }
        let state = contentState(
            phaseTitle: phaseTitle,
            remainingSeconds: remainingSeconds,
            segmentEndDate: segmentEndDate,
            isRunning: isRunning
        )
        guard state != lastState else { return }
        lastState = state
        Task {
            await activity.update(ActivityContent(state: state, staleDate: state.segmentEndDate))
        }
    }

    private var lastState: TimerActivityAttributes.ContentState?

    private func contentState(
        phaseTitle: String,
        remainingSeconds: Int,
        segmentEndDate: Date?,
        isRunning: Bool
    ) -> TimerActivityAttributes.ContentState {
        let endDate = isRunning ? segmentEndDate : nil
        return TimerActivityAttributes.ContentState(
            phaseTitle: phaseTitle,
            remainingSeconds: max(0, remainingSeconds),
            isRunning: isRunning && endDate != nil,
            segmentEndDate: endDate
        )
    }

    func end(immediate: Bool = false) {
        guard let activity else { return }
        let current = activity.content.state
        Task {
            await activity.end(
                ActivityContent(state: current, staleDate: nil),
                dismissalPolicy: immediate ? .immediate : .default
            )
        }
        self.activity = nil
        lastState = nil
    }
}
