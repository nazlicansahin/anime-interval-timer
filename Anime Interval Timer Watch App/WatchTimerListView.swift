import SwiftUI

struct WatchTimerListView: View {
    @ObservedObject private var sync = WatchSyncStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                WatchBackgroundView(useMainBackground: true)
                if let session = sync.activeSession {
                    WatchTimerRunView(session: session, store: sync, phoneControlled: true)
                } else {
                    timerList
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AnimeTimer.self) { timer in
                WatchTimerRunView(timer: timer, store: sync, phoneControlled: false)
            }
            .onAppear {
                sync.reloadFromLocalCache()
            }
        }
    }

    @ViewBuilder
    private var timerList: some View {
        GeometryReader { geo in
            Group {
                if sync.timers.isEmpty {
                    ContentUnavailableView(
                        "No Timers",
                        systemImage: "timer",
                        description: Text("Open the iPhone app to sync timers.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            Text("Timers")
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.59, green: 0.42, blue: 0.60))

                            ForEach(sync.timers) { timer in
                                NavigationLink(value: timer) {
                                    WatchTimerRow(timer: timer, isActiveOnPhone: false)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.55))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .center)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct WatchTimerRow: View {
    let timer: AnimeTimer
    let isActiveOnPhone: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(timer.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.title)
                    .font(.headline)
                    .lineLimit(1)
                if let loops = timer.loopsCount {
                    Text("\(loops) loops")
                        .font(.caption2)
                        .foregroundStyle(.black)
                }
            }
        }
    }
}
