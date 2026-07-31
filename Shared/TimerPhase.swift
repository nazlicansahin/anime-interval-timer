import Foundation

enum TimerPhase: Int, CaseIterable {
    case start = 0
    case focus = 1
    case break_ = 2

    var englishTitle: String {
        switch self {
        case .start: return "Start"
        case .focus: return "Focus"
        case .break_: return "Break"
        }
    }

    var bgImageName: String {
        switch self {
        case .start: return "bg-green"
        case .focus: return "bg-pink"
        case .break_: return "bg-blue"
        }
    }

    var startBtnImageName: String {
        switch self {
        case .start: return "start-btn-green"
        case .focus: return "start-btn-pink"
        case .break_: return "start-btn-blue"
        }
    }

    var stopBtnImageName: String {
        switch self {
        case .start: return "stop-btn-green"
        case .focus: return "stop-btn-pink"
        case .break_: return "stop-btn-blue"
        }
    }
}
