import Foundation
import WatchConnectivity

final class PhoneWatchConnectivity: NSObject {
    static let shared = PhoneWatchConnectivity()

    private let storage = UserDefaultsTimersStorage()
    private var activeSession: ActiveTimerSession?
    private var storageObserver: NSObjectProtocol?

    private override init() {
        super.init()
        storageObserver = NotificationCenter.default.addObserver(
            forName: .timerStorageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pushCurrentState()
        }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func updateActiveSession(_ session: ActiveTimerSession?) {
        activeSession = session
        pushCurrentState()
    }

    func clearActiveSession() {
        activeSession = nil
        pushCurrentState()
    }

    func pushNow() {
        pushCurrentState()
    }

    private func pushCurrentState() {
        let payload = TimerSyncPayload(
            timers: storage.loadTimers(),
            activeSession: activeSession
        )
        push(payload)
    }

    private func push(_ payload: TimerSyncPayload) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(payload) else { return }

        do {
            try session.updateApplicationContext([TimerSyncContextKey.payload: data])
        } catch {
            // Watch may be unavailable; ignore.
        }

        if session.isReachable {
            session.sendMessage([TimerSyncContextKey.payload: data], replyHandler: nil) { _ in }
        }
    }
}

extension PhoneWatchConnectivity: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        pushCurrentState()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            pushCurrentState()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingWatchMessage(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncomingWatchMessage(userInfo)
    }

    private func handleIncomingWatchMessage(_ message: [String: Any]) {
        if let commandRaw = message[TimerSyncContextKey.timerCommand] as? String,
           let command = WatchTimerCommand(rawValue: commandRaw) {
            NotificationCenter.default.post(
                name: .watchTimerCommand,
                object: nil,
                userInfo: [TimerSyncContextKey.timerCommand: commandRaw]
            )
            if command == .cancel {
                clearActiveSession()
            }
            return
        }

        if message[TimerSyncContextKey.cancelSession] as? Bool == true {
            clearActiveSession()
            NotificationCenter.default.post(name: .watchRequestedCancelTimer, object: nil)
        }
    }
}
