import ActivityKit
import Foundation

@MainActor
final class TimerLiveActivityManager {
    private var activity: Activity<TimerActivityAttributes>?

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func sync(timerTitle: String, phaseTitle: String, remainingSeconds: Int, isRunning: Bool) {
        guard isSupported else { return }
        if activity == nil {
            start(timerTitle: timerTitle, phaseTitle: phaseTitle, remainingSeconds: remainingSeconds, isRunning: isRunning)
        } else {
            update(phaseTitle: phaseTitle, remainingSeconds: remainingSeconds, isRunning: isRunning)
        }
    }

    func start(timerTitle: String, phaseTitle: String, remainingSeconds: Int, isRunning: Bool) {
        guard isSupported else { return }
        end(immediate: true)

        let attributes = TimerActivityAttributes(timerTitle: timerTitle)
        let state = TimerActivityAttributes.ContentState(
            phaseTitle: phaseTitle,
            remainingSeconds: max(0, remainingSeconds),
            isRunning: isRunning
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func update(phaseTitle: String, remainingSeconds: Int, isRunning: Bool) {
        guard let activity else { return }
        let state = TimerActivityAttributes.ContentState(
            phaseTitle: phaseTitle,
            remainingSeconds: max(0, remainingSeconds),
            isRunning: isRunning
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
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
    }
}
