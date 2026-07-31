import SwiftUI

struct WatchBackgroundView: View {
    var phase: TimerPhase?
    var useMainBackground: Bool = false

    private var imageName: String {
        if useMainBackground {
            return "background-img"
        }
        return (phase ?? .start).bgImageName
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}
