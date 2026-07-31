import Foundation

struct TimerSyncPayload: Codable {
    var timers: [AnimeTimer]
    var activeSession: ActiveTimerSession?
}

struct ActiveTimerSession: Codable, Equatable, Identifiable {
    var id: UUID { timer.id }

    var timer: AnimeTimer
    var phaseRawValue: Int
    var currentLoop: Int
    var remainingSeconds: TimeInterval
    var segmentEndDate: Date?
    var isRunning: Bool
    var isFinished: Bool

    var phase: TimerPhase {
        TimerPhase(rawValue: phaseRawValue) ?? .start
    }
}

extension Notification.Name {
    static let timerStorageDidChange = Notification.Name("timerStorageDidChange")
}

enum TimerSyncContextKey {
    static let payload = "timerSyncPayload"
    static let cancelSession = "cancelActiveSession"
    static let timerCommand = "timerCommand"
}

enum WatchTimerCommand: String {
    case toggleRunning
    case previousPhase
    case nextPhase
    case cancel
}

extension Notification.Name {
    static let watchRequestedCancelTimer = Notification.Name("watchRequestedCancelTimer")
    static let watchTimerCommand = Notification.Name("watchTimerCommand")
}
