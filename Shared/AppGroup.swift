import Foundation

enum AppGroup {
    static let identifier = "group.dev.nazlican.Anime-Interval-Timer"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
