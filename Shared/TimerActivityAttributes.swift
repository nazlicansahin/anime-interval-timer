import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phaseTitle: String
        var remainingSeconds: Int
        var isRunning: Bool
        /// Wall-clock end of the current segment. The Live Activity counts down to this date itself, so the lock screen and Dynamic Island keep moving while the app is suspended.
        var segmentEndDate: Date?
    }

    var timerTitle: String
}
