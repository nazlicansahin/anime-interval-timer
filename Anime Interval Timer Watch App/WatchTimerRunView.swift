import SwiftUI
import Combine

@MainActor
final class WatchTimerRunViewModel: ObservableObject {
    @Published private(set) var phase: TimerPhase = .start
    @Published private(set) var remainingSeconds: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isFinished = false
    @Published private(set) var isPhoneControlled = false
    @Published private(set) var currentLoop = 0

    let timer: AnimeTimer

    private var segmentEndDate: Date?
    private var ticker: AnyCancellable?

    init(timer: AnimeTimer) {
        self.timer = timer
        reset()
    }

    init(session: ActiveTimerSession) {
        self.timer = session.timer
        applyRemoteSession(session)
    }

    var displayTitle: String {
        let raw = timer.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Quick start" : raw
    }

    var formattedTime: String {
        let s = max(0, Int(ceil(remainingSeconds)))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    var loopProgressText: String {
        let total = max(1, timer.loopsCount ?? 1)
        let current = min(currentLoop + 1, total)
        return "\(current)/\(total)"
    }

    var controlButtonImageName: String {
        isRunning ? phase.stopBtnImageName : phase.startBtnImageName
    }

    func toggleRunning() {
        if isPhoneControlled {
            WatchConnectivityService.shared.sendTimerCommand(.toggleRunning)
            return
        }
        if isRunning {
            pause()
        } else if isFinished {
            reset()
            start()
        } else {
            start()
        }
    }

    func previousPhase() {
        if isPhoneControlled {
            WatchConnectivityService.shared.sendTimerCommand(.previousPhase)
            return
        }
        guard !isFinished else { return }
        pause()
        if phase == .break_ {
            phase = .focus
            remainingSeconds = timer.focusDuration
        } else if phase == .focus {
            if currentLoop > 0 {
                currentLoop -= 1
                phase = .break_
                remainingSeconds = timer.breakDuration
            } else {
                phase = .start
                remainingSeconds = timer.startDuration
            }
        }
        start()
    }

    func nextPhase() {
        if isPhoneControlled {
            WatchConnectivityService.shared.sendTimerCommand(.nextPhase)
            return
        }
        guard !isFinished else { return }
        pause()
        advancePhase()
        if !isFinished {
            start()
        }
    }

    func cancel() {
        if isPhoneControlled {
            WatchConnectivityService.shared.sendTimerCommand(.cancel)
            return
        }
        pause()
        isFinished = false
        phase = .start
        currentLoop = 0
        remainingSeconds = timer.startDuration
        segmentEndDate = nil
        stopTicker()
    }

    func applyRemoteSession(_ session: ActiveTimerSession) {
        isPhoneControlled = true
        phase = session.phase
        currentLoop = session.currentLoop
        isFinished = session.isFinished
        isRunning = session.isRunning
        segmentEndDate = session.segmentEndDate

        if let end = session.segmentEndDate, session.isRunning {
            remainingSeconds = max(0, end.timeIntervalSinceNow)
            startTicker()
        } else {
            remainingSeconds = session.remainingSeconds
            stopTicker()
        }
    }

    func reset() {
        guard !isPhoneControlled else { return }
        phase = .start
        currentLoop = 0
        remainingSeconds = timer.startDuration
        isRunning = false
        isFinished = false
        segmentEndDate = nil
        stopTicker()
    }

    private func start() {
        guard !isFinished, !isPhoneControlled else { return }
        isRunning = true
        segmentEndDate = Date().addingTimeInterval(remainingSeconds)
        startTicker()
    }

    private func pause() {
        guard !isPhoneControlled else { return }
        if let end = segmentEndDate {
            remainingSeconds = max(0, end.timeIntervalSinceNow)
        }
        isRunning = false
        segmentEndDate = nil
        stopTicker()
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncFromClock()
            }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func syncFromClock() {
        guard isRunning, let end = segmentEndDate else { return }
        remainingSeconds = max(0, end.timeIntervalSinceNow)

        if remainingSeconds <= 0 {
            advancePhase()
            if isRunning && !isFinished {
                segmentEndDate = Date().addingTimeInterval(remainingSeconds)
                if remainingSeconds <= 0 {
                    syncFromClock()
                }
            }
        }
    }

    private func advancePhase() {
        let nextRaw = phase.rawValue + 1
        if nextRaw > 2 {
            currentLoop += 1
            let loops = max(1, timer.loopsCount ?? 1)
            if currentLoop >= loops {
                finish()
                return
            }
            phase = .focus
            remainingSeconds = timer.focusDuration
        } else {
            phase = TimerPhase(rawValue: nextRaw) ?? .focus
            remainingSeconds = phaseDuration()
        }
    }

    private func phaseDuration() -> TimeInterval {
        switch phase {
        case .start: return timer.startDuration
        case .focus: return timer.focusDuration
        case .break_: return timer.breakDuration
        }
    }

    private func finish() {
        isFinished = true
        isRunning = false
        segmentEndDate = nil
        remainingSeconds = 0
        stopTicker()
    }

    func handleForeground() {
        guard isRunning else { return }
        syncFromClock()
    }
}

struct WatchTimerRunView: View {
    @StateObject private var viewModel: WatchTimerRunViewModel
    @ObservedObject var store: WatchSyncStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var didMarkUsed = false

    private let phoneControlled: Bool

    init(timer: AnimeTimer, store: WatchSyncStore, phoneControlled: Bool) {
        _viewModel = StateObject(wrappedValue: WatchTimerRunViewModel(timer: timer))
        self.store = store
        self.phoneControlled = phoneControlled
    }

    init(session: ActiveTimerSession, store: WatchSyncStore, phoneControlled: Bool) {
        _viewModel = StateObject(wrappedValue: WatchTimerRunViewModel(session: session))
        self.store = store
        self.phoneControlled = phoneControlled
    }

    var body: some View {
        ZStack {
            WatchBackgroundView(phase: viewModel.isFinished ? .start : viewModel.phase)

            VStack(spacing: 12) {
                if phoneControlled {
                    HStack(spacing: 4) {
                        Image(systemName: "iphone")
                        Text("From iPhone")
                    }
                    .font(.caption2)
                    .foregroundStyle(Color(red: 0.59, green: 0.42, blue: 0.60))
                }

                if !viewModel.isFinished {
                    Text(viewModel.loopProgressText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                }

                if viewModel.isFinished {
                    Text("Done! ✨")
                        .font(.title3.bold())
                        .foregroundStyle(Color(red: 0.59, green: 0.42, blue: 0.60))
                } else {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .foregroundStyle(Color(red: 0.25, green: 0.18, blue: 0.28))
                        .padding(.horizontal, 4)

                    controlRow
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 8)
            .padding(.top, 6)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: topBarTapped) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.25, green: 0.18, blue: 0.28))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            guard !phoneControlled, !didMarkUsed else { return }
            didMarkUsed = true
            _ = store.markUsedAndReturn(viewModel.timer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.handleForeground()
            }
        }
        .onChange(of: store.activeSession) { _, session in
            guard phoneControlled else { return }
            if let session {
                viewModel.applyRemoteSession(session)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 4) {
            Button(action: viewModel.previousPhase) {
                Image("next-tour-btn")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Button(action: viewModel.toggleRunning) {
                Image(viewModel.controlButtonImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Button(action: viewModel.nextPhase) {
                Image("next-tour-btn")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }

    private func topBarTapped() {
        if phoneControlled {
            viewModel.cancel()
            return
        }
        if viewModel.isFinished {
            dismiss()
            return
        }
        viewModel.cancel()
        dismiss()
    }
}
