import Foundation

protocol TimersStoring {
    func loadTimers() -> [AnimeTimer]
    func saveTimers(_ timers: [AnimeTimer])

    func add(_ timer: AnimeTimer)
    func update(_ timer: AnimeTimer)
    func delete(id: UUID)
}

final class UserDefaultsTimersStorage: TimersStoring {

    private enum Keys {
        static let timers = "anime_interval_timer.timers"
        static let didMigrateToAppGroup = "anime_interval_timer.did_migrate_to_app_group"
    }

    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(userDefaults: UserDefaults = AppGroup.userDefaults) {
        self.userDefaults = userDefaults
        Self.migrateLegacyTimersIfNeeded(into: userDefaults)
    }

    func loadTimers() -> [AnimeTimer] {
        guard let data = userDefaults.data(forKey: Keys.timers) else {
            return []
        }

        do {
            return try decoder.decode([AnimeTimer].self, from: data)
        } catch {
            userDefaults.removeObject(forKey: Keys.timers)
            return []
        }
    }

    func saveTimers(_ timers: [AnimeTimer]) {
        do {
            let data = try encoder.encode(timers)
            userDefaults.set(data, forKey: Keys.timers)
            NotificationCenter.default.post(name: .timerStorageDidChange, object: nil)
        } catch {
            // no-op
        }
    }

    func add(_ timer: AnimeTimer) {
        var timers = loadTimers()
        timers.append(timer)
        saveTimers(timers)
    }

    func update(_ timer: AnimeTimer) {
        var timers = loadTimers()
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else {
            return
        }
        timers[index] = timer
        saveTimers(timers)
    }

    func delete(id: UUID) {
        var timers = loadTimers()
        timers.removeAll { $0.id == id }
        saveTimers(timers)
    }

    private static func migrateLegacyTimersIfNeeded(into groupDefaults: UserDefaults) {
        guard !groupDefaults.bool(forKey: Keys.didMigrateToAppGroup) else { return }

        if let legacyData = UserDefaults.standard.data(forKey: Keys.timers),
           groupDefaults.data(forKey: Keys.timers) == nil {
            groupDefaults.set(legacyData, forKey: Keys.timers)
        }

        groupDefaults.set(true, forKey: Keys.didMigrateToAppGroup)
    }
}
