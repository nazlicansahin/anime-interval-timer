import Foundation
import Combine

@MainActor
final class WatchSyncStore: ObservableObject {
    static let shared = WatchSyncStore()

    @Published private(set) var timers: [AnimeTimer] = []
    @Published var activeSession: ActiveTimerSession?

    private let storage: TimersStoring

    init(storage: TimersStoring = UserDefaultsTimersStorage()) {
        self.storage = storage
        reloadFromLocalCache()
    }

    func apply(_ payload: TimerSyncPayload) {
        timers = Self.sorted(payload.timers)
        if !payload.timers.isEmpty {
            storage.saveTimers(payload.timers)
        }
        activeSession = payload.activeSession
    }

    func reloadFromLocalCache() {
        timers = Self.sorted(storage.loadTimers())
    }

    func markUsedAndReturn(_ timer: AnimeTimer) -> AnimeTimer {
        var updated = timer
        updated.usageCount += 1
        storage.update(updated)
        reloadFromLocalCache()
        return updated
    }

    private static func sorted(_ timers: [AnimeTimer]) -> [AnimeTimer] {
        timers.sorted { lhs, rhs in
            if lhs.usageCount != rhs.usageCount {
                return lhs.usageCount > rhs.usageCount
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
