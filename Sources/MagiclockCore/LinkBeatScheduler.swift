import Foundation

public struct LinkBeatSnapshot: Equatable {
    public let beat: Double
    public let tempo: Double
    public let isPlaying: Bool

    public init(beat: Double, tempo: Double, isPlaying: Bool) {
        self.beat = beat
        self.tempo = tempo
        self.isPlaying = isPlaying
    }

    public init(linkStatus status: AbletonLinkStatus) {
        self.init(
            beat: status.beat,
            tempo: status.tempo,
            isPlaying: status.isEnabled && status.isPlaying
        )
    }
}

public enum BeatKind: Equatable {
    case regular
    case downbeat
}

public struct LinkBeatEvent: Equatable {
    public let snapshot: LinkBeatSnapshot
    public let kind: BeatKind

    public init(snapshot: LinkBeatSnapshot, kind: BeatKind) {
        self.snapshot = snapshot
        self.kind = kind
    }
}

public struct LinkBeatScheduler {
    private var previousBeatIndex: Int?

    public init() {}

    public mutating func consumeEvent(_ snapshot: LinkBeatSnapshot, beatsPerBar: Int = 4) -> LinkBeatEvent? {
        guard snapshot.isPlaying else {
            previousBeatIndex = nil
            return nil
        }

        let beatIndex = Int(floor(snapshot.beat))
        defer {
            previousBeatIndex = beatIndex
        }

        guard let previousBeatIndex else {
            return nil
        }

        guard beatIndex > previousBeatIndex else {
            return nil
        }

        let normalizedBeatIndex = ((beatIndex % beatsPerBar) + beatsPerBar) % beatsPerBar
        let kind: BeatKind = normalizedBeatIndex == 0 ? .downbeat : .regular

        return LinkBeatEvent(snapshot: snapshot, kind: kind)
    }

    public mutating func consume(_ snapshot: LinkBeatSnapshot) -> Bool {
        consumeEvent(snapshot) != nil
    }

    public mutating func reset() {
        previousBeatIndex = nil
    }
}
