import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phaseTitle: String
        var remainingSeconds: Int
        var isRunning: Bool
    }

    var timerTitle: String
}
