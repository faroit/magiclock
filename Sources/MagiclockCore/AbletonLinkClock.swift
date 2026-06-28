#if SWIFT_PACKAGE
import AbletonLinkBridge
#endif
import Foundation

public struct AbletonLinkStatus {
    public let isEnabled: Bool
    public let isStartStopSyncEnabled: Bool
    public let peerCount: UInt64
    public let tempo: Double
    public let beat: Double
    public let phase: Double
    public let isPlaying: Bool

    public init(
        isEnabled: Bool,
        isStartStopSyncEnabled: Bool,
        peerCount: UInt64,
        tempo: Double,
        beat: Double,
        phase: Double,
        isPlaying: Bool
    ) {
        self.isEnabled = isEnabled
        self.isStartStopSyncEnabled = isStartStopSyncEnabled
        self.peerCount = peerCount
        self.tempo = tempo
        self.beat = beat
        self.phase = phase
        self.isPlaying = isPlaying
    }
}

public final class AbletonLinkClock {
    public var onBeat: ((LinkBeatEvent) -> Void)?
    public var onStatusUpdate: ((AbletonLinkStatus) -> Void)?

    private let link: MagicAbletonLinkRef
    private let sessionState: MagicAbletonLinkSessionStateRef
    private let quantum: Double
    private let pollInterval: TimeInterval
    private var scheduler = LinkBeatScheduler()
    private var timer: Timer?

    public init(initialTempo: Double = 120, quantum: Double = 4, pollInterval: TimeInterval = 0.01) {
        guard let link = MagicAbletonLinkCreate(initialTempo) else {
            fatalError("Unable to create Ableton Link instance")
        }
        guard let sessionState = MagicAbletonLinkSessionStateCreate() else {
            MagicAbletonLinkDestroy(link)
            fatalError("Unable to create Ableton Link session state")
        }

        self.link = link
        self.sessionState = sessionState
        self.quantum = quantum
        self.pollInterval = pollInterval

        MagicAbletonLinkEnableStartStopSync(link, true)
    }

    deinit {
        stop()
        MagicAbletonLinkSessionStateDestroy(sessionState)
        MagicAbletonLinkDestroy(link)
    }

    public var isEnabled: Bool {
        MagicAbletonLinkIsEnabled(link)
    }

    public func setEnabled(_ enabled: Bool) {
        MagicAbletonLinkEnable(link, enabled)
        scheduler.reset()
        onStatusUpdate?(captureStatus())
    }

    public func start() {
        guard timer == nil else {
            return
        }

        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        scheduler.reset()
    }

    public func captureStatus() -> AbletonLinkStatus {
        MagicAbletonLinkCaptureAppSessionState(link, sessionState)

        let timeMicros = MagicAbletonLinkClockMicros(link)
        let tempo = MagicAbletonLinkSessionTempo(sessionState)
        let beat = MagicAbletonLinkSessionBeatAtTime(sessionState, timeMicros, quantum)
        let phase = MagicAbletonLinkSessionPhaseAtTime(sessionState, timeMicros, quantum)

        return AbletonLinkStatus(
            isEnabled: MagicAbletonLinkIsEnabled(link),
            isStartStopSyncEnabled: MagicAbletonLinkIsStartStopSyncEnabled(link),
            peerCount: MagicAbletonLinkNumPeers(link),
            tempo: tempo,
            beat: beat,
            phase: phase,
            isPlaying: MagicAbletonLinkSessionIsPlaying(sessionState)
        )
    }

    private func poll() {
        let status = captureStatus()
        onStatusUpdate?(status)

        let snapshot = LinkBeatSnapshot(linkStatus: status)

        if let event = scheduler.consumeEvent(snapshot) {
            onBeat?(event)
        }
    }
}
