import MagiclockCore
import Darwin

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(description: message)
    }
}

func testInitialSampleDoesNotTriggerBeat() throws {
    var scheduler = LinkBeatScheduler()

    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 12.25, tempo: 120, isPlaying: true)), "initial sample triggered a beat")
}

func testTriggersWhenBeatCrossesIntoNextIntegerBeat() throws {
    var scheduler = LinkBeatScheduler()

    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 12.95, tempo: 120, isPlaying: true)), "initial sample triggered a beat")
    try expect(scheduler.consume(LinkBeatSnapshot(beat: 13.02, tempo: 120, isPlaying: true)), "integer beat crossing did not trigger")
}

func testDoesNotRetriggerWithinSameIntegerBeat() throws {
    var scheduler = LinkBeatScheduler()

    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 4.01, tempo: 120, isPlaying: true)), "initial sample triggered a beat")
    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 4.25, tempo: 120, isPlaying: true)), "same beat retriggered at 4.25")
    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 4.99, tempo: 120, isPlaying: true)), "same beat retriggered at 4.99")
}

func testPausedSnapshotResetsBeatTracking() throws {
    var scheduler = LinkBeatScheduler()

    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 2.75, tempo: 120, isPlaying: true)), "initial sample triggered a beat")
    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 3.10, tempo: 120, isPlaying: false)), "paused sample triggered a beat")
    try expect(!scheduler.consume(LinkBeatSnapshot(beat: 3.20, tempo: 120, isPlaying: true)), "first resumed sample triggered a beat")
    try expect(scheduler.consume(LinkBeatSnapshot(beat: 4.01, tempo: 120, isPlaying: true)), "post-resume crossing did not trigger")
}

func testLinkStatusSnapshotFollowsTransportState() throws {
    let stoppedStatus = AbletonLinkStatus(
        isEnabled: true,
        isStartStopSyncEnabled: true,
        peerCount: 1,
        tempo: 120,
        beat: 8.25,
        phase: 0.25,
        isPlaying: false
    )

    try expect(!LinkBeatSnapshot(linkStatus: stoppedStatus).isPlaying, "stopped Link transport should pause haptics")

    let playingStatus = AbletonLinkStatus(
        isEnabled: true,
        isStartStopSyncEnabled: true,
        peerCount: 1,
        tempo: 120,
        beat: 8.25,
        phase: 0.25,
        isPlaying: true
    )

    try expect(LinkBeatSnapshot(linkStatus: playingStatus).isPlaying, "playing Link transport should allow haptics")
}

func testBeatEventsMarkEveryFourthBeatAsDownbeat() throws {
    var scheduler = LinkBeatScheduler()

    try expect(scheduler.consumeEvent(LinkBeatSnapshot(beat: 3.95, tempo: 120, isPlaying: true)) == nil, "initial sample triggered a beat event")

    let downbeat = scheduler.consumeEvent(LinkBeatSnapshot(beat: 4.02, tempo: 120, isPlaying: true))
    try expect(downbeat?.kind == .downbeat, "beat 4 should be a downbeat")

    let regularBeat = scheduler.consumeEvent(LinkBeatSnapshot(beat: 5.02, tempo: 120, isPlaying: true))
    try expect(regularBeat?.kind == .regular, "beat 5 should be a regular beat")
}

let tests: [(String, () throws -> Void)] = [
    ("initial sample does not trigger beat", testInitialSampleDoesNotTriggerBeat),
    ("triggers when beat crosses into next integer beat", testTriggersWhenBeatCrossesIntoNextIntegerBeat),
    ("does not retrigger within same integer beat", testDoesNotRetriggerWithinSameIntegerBeat),
    ("paused snapshot resets beat tracking", testPausedSnapshotResetsBeatTracking),
    ("Link status snapshot follows transport state", testLinkStatusSnapshotFollowsTransportState),
    ("beat events mark every fourth beat as downbeat", testBeatEventsMarkEveryFourthBeatAsDownbeat)
]

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("PASS \(name)")
    } catch {
        failures += 1
        print("FAIL \(name): \(error)")
    }
}

if failures > 0 {
    print("\(failures) test(s) failed")
    exit(1)
}

print("\(tests.count) test(s) passed")
