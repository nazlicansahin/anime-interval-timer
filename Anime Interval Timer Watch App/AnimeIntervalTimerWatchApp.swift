import SwiftUI

@main
struct AnimeIntervalTimerWatchApp: App {
    init() {
        WatchConnectivityService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchTimerListView()
        }
    }
}
