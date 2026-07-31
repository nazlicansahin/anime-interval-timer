import Foundation

enum TimerKind: String, Codable, CaseIterable {
    case study
    case workout
}

struct AnimeTimer: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var loopsCount: Int?

    var startDuration: TimeInterval
    var focusDuration: TimeInterval
    var breakDuration: TimeInterval

    var emoji: String
    var usageCount: Int
    let createdAt: Date

    var timerKind: TimerKind

    init(
        id: UUID,
        title: String,
        loopsCount: Int?,
        startDuration: TimeInterval,
        focusDuration: TimeInterval,
        breakDuration: TimeInterval,
        emoji: String,
        usageCount: Int,
        createdAt: Date,
        timerKind: TimerKind = .study
    ) {
        self.id = id
        self.title = title
        self.loopsCount = loopsCount
        self.startDuration = startDuration
        self.focusDuration = focusDuration
        self.breakDuration = breakDuration
        self.emoji = emoji
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.timerKind = timerKind
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        loopsCount = try c.decodeIfPresent(Int.self, forKey: .loopsCount)
        startDuration = try c.decode(TimeInterval.self, forKey: .startDuration)
        focusDuration = try c.decode(TimeInterval.self, forKey: .focusDuration)
        breakDuration = try c.decode(TimeInterval.self, forKey: .breakDuration)
        emoji = try c.decode(String.self, forKey: .emoji)
        usageCount = try c.decode(Int.self, forKey: .usageCount)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        timerKind = try c.decodeIfPresent(TimerKind.self, forKey: .timerKind) ?? .study
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(loopsCount, forKey: .loopsCount)
        try c.encode(startDuration, forKey: .startDuration)
        try c.encode(focusDuration, forKey: .focusDuration)
        try c.encode(breakDuration, forKey: .breakDuration)
        try c.encode(emoji, forKey: .emoji)
        try c.encode(usageCount, forKey: .usageCount)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(timerKind, forKey: .timerKind)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, loopsCount, startDuration, focusDuration, breakDuration, emoji, usageCount, createdAt, timerKind
    }
}
