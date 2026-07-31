import Foundation
import WatchConnectivity

final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func decodePayload(from context: [String: Any]) -> TimerSyncPayload? {
        guard let data = context[TimerSyncContextKey.payload] as? Data else { return nil }
        return try? JSONDecoder().decode(TimerSyncPayload.self, from: data)
    }

    private func apply(context: [String: Any]) {
        guard let payload = decodePayload(from: context) else { return }
        Task { @MainActor in
            WatchSyncStore.shared.apply(payload)
        }
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        apply(context: session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(context: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message[TimerSyncContextKey.timerCommand] != nil {
            return
        }
        if message[TimerSyncContextKey.cancelSession] as? Bool == true {
            return
        }
        apply(context: message)
    }
}

extension WatchConnectivityService {
    func sendTimerCommand(_ command: WatchTimerCommand) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let message = [TimerSyncContextKey.timerCommand: command.rawValue] as [String: Any]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        } else {
            session.transferUserInfo(message)
        }
    }

    func requestCancelOnPhone() {
        sendTimerCommand(.cancel)
    }
}
