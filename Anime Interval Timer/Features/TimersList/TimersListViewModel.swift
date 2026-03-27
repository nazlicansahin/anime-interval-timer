import Foundation

/// ViewModel for the "My Timers" screen.
/// Talks to storage, keeps timers in memory, and exposes data in a form suitable for the view.
final class TimersListViewModel {

    // MARK: - Nested types

    struct DisplayTimer {
        let id: UUID
        let title: String
        let loopsText: String?
        let startText: String
        let focusText: String
        let breakText: String
        let emoji: String
    }

    // MARK: - Properties

    private let storage: TimersStoring

    /// In-memory list of timers, always kept sorted by usageCount (desc) then createdAt (desc).
    private var timers: [AnimeTimer] = []

    /// Fixed emoji set to choose from when creating a new timer.
    /// The actual choice will happen in the create timer flow, but ViewModel owns the source of truth.
    let availableEmojis: [String] = [
        "⏳", "📚", "💪", "✨", "🔥", "🌸", "🎧", "🍣", "🗡️", "😼"
    ]

    // MARK: - Init

    init(storage: TimersStoring = UserDefaultsTimersStorage()) {
        self.storage = storage
    }

    // MARK: - Public API

    func reload() {
        timers = storage.loadTimers()
        sortTimers()
    }

    var numberOfTimers: Int {
        timers.count
    }

    func timer(at index: Int) -> DisplayTimer {
        let timer = timers[index]

        return DisplayTimer(
            id: timer.id,
            title: timer.title,
            loopsText: timer.loopsCount.flatMap { "\($0) Loops" },
            startText: Self.format(seconds: timer.startDuration),
            focusText: Self.format(seconds: timer.focusDuration),
            breakText: Self.format(seconds: timer.breakDuration),
            emoji: timer.emoji
        )
    }

    func deleteTimer(at index: Int) {
        guard timers.indices.contains(index) else { return }
        let id = timers[index].id
        timers.remove(at: index)
        storage.delete(id: id)
    }

    /// Called when user starts a timer from the list.
    /// Increments usageCount, persists, and re-sorts the list.
    func markTimerAsUsed(at index: Int) -> AnimeTimer? {
        guard timers.indices.contains(index) else { return nil }
        var timer = timers[index]
        timer.usageCount += 1
        timers[index] = timer
        storage.update(timer)
        sortTimers()
        return timer
    }

    /// Adds a newly created timer and re-sorts the list.
    func addNewTimer(_ timer: AnimeTimer) {
        timers.append(timer)
        storage.add(timer)
        sortTimers()
    }

    /// Full model for editing (same order as `timer(at:)` display index).
    func storedTimer(at index: Int) -> AnimeTimer? {
        guard timers.indices.contains(index) else { return nil }
        return timers[index]
    }

    /// Persists changes to an existing timer (same `id`).
    func updateExistingTimer(_ timer: AnimeTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        timers[index] = timer
        storage.update(timer)
        sortTimers()
    }

    // MARK: - Helpers

    private func sortTimers() {
        timers.sort { lhs, rhs in
            if lhs.usageCount != rhs.usageCount {
                return lhs.usageCount > rhs.usageCount
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private static func format(seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

