import AppKit
import CoreMIDI
import Darwin.Mach
#if SWIFT_PACKAGE
import MagiclockCore
#endif

private let beatTicks = 24
private let smoothingFactor = 0.5
private let alreadyBeenLaunchedKey = "AlreadyBeenLaunched"
private let showBPMKey = "showBPM"
private let abletonLinkEnabledKey = "abletonLinkEnabled"
private let downbeatAccentModeKey = "downbeatAccentMode"
private let beatsPerBar = 4

private enum DownbeatAccentMode: String, CaseIterable {
    case off
    case light
    case strong

    var title: String {
        switch self {
        case .off:
            return "Off"
        case .light:
            return "Light"
        case .strong:
            return "Strong"
        }
    }
}

@objc(AppDelegate)
final class AppDelegate: NSObject, NSApplicationDelegate {
    fileprivate var showBPM = false
    fileprivate var abletonLinkEnabled = false
    fileprivate var midiBeatIndex = 0
    fileprivate var clockCount = beatTicks
    fileprivate var bpm = 0.0
    fileprivate var currentClockTime = 0.0
    fileprivate var previousClockTime = 0.0
    fileprivate var intervalInNanoseconds = 0.0
    fileprivate var tickDelta = 0.0

    private var statusItem: NSStatusItem?
    private var notic: NSImage?
    private var tic: NSImage?
    private var abletonLinkMenu: NSMenuItem?
    private var abletonLinkPeersMenu: NSMenuItem?
    private var downbeatAccentMenuItems: [DownbeatAccentMode: NSMenuItem] = [:]
    private var bpmMenu: NSMenuItem?
    private var diagnosticsWindow: NSWindow?
    private let formatter = NumberFormatter()
    private let forceTouchMonitor = ForceTouchDeviceMonitor()
    private let abletonLinkClock = AbletonLinkClock()
    private var latestAbletonLinkStatus: AbletonLinkStatus?
    private var downbeatAccentMode = DownbeatAccentMode.strong
    private var midiClient = MIDIClientRef()
    private var midiDestination = MIDIEndpointRef()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: alreadyBeenLaunchedKey) && !defaults.bool(forKey: showBPMKey) {
            defaults.set(true, forKey: alreadyBeenLaunchedKey)
            defaults.set(true, forKey: showBPMKey)
            showHelpModal()
        }

        showBPM = defaults.bool(forKey: showBPMKey)
        abletonLinkEnabled = defaults.bool(forKey: abletonLinkEnabledKey)
        if let rawAccentMode = defaults.string(forKey: downbeatAccentModeKey),
           let accentMode = DownbeatAccentMode(rawValue: rawAccentMode) {
            downbeatAccentMode = accentMode
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(testForceTouchAvailability(_:)),
            name: ForceTouchDeviceMonitor.availabilityDidChangeNotification,
            object: nil
        )
        showModalForceTouchAvailable(forceTouchMonitor.isForceTouchCapableDeviceAvailable())

        notic = loadImage(named: "trayicon")
        notic?.isTemplate = true
        tic = loadImage(named: "trayicon-tic")
        tic?.isTemplate = true

        setupStatusItem()
        setupNumberFormatter()
        setupMIDI()
        setupAbletonLink()

        Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(renderBPM(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        abletonLinkClock.stop()
        forceTouchMonitor.stop()
    }

    @objc private func testForceTouchAvailability(_ note: Notification) {
        guard let available = note.userInfo?[ForceTouchDeviceMonitor.availabilityUserInfoKey] as? Bool else {
            return
        }
        showModalForceTouchAvailable(available)
    }

    @objc private func showModalForceTouchAvailable(_ available: Bool) {
        guard !available else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "No supported Trackpad found"
        alert.informativeText = "Your trackpad does not support haptic feedback."
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }

    @objc private func showHelpModal() {
        let alert = NSAlert()
        alert.messageText = "How to use Magiclock?"
        alert.informativeText = "Connect any MIDI Clock Output to \"Magiclock\" and feel the beat..."
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = ""
        statusItem?.button?.image = notic
        statusItem?.highlightMode = false
        updateStatusItemMenu()
    }

    private func loadImage(named name: String) -> NSImage? {
        if let image = NSImage(named: name) {
            return image
        }

        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        #endif

        return nil
    }

    private func setupNumberFormatter() {
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
    }

    private func setupMIDI() {
        MIDIClientCreate("Magiclock MIDI client" as CFString, nil, Unmanaged.passUnretained(self).toOpaque(), &midiClient)
        MIDIDestinationCreate(
            midiClient,
            "Magiclock" as CFString,
            midiInputCallback,
            Unmanaged.passUnretained(self).toOpaque(),
            &midiDestination
        )
    }

    private func setupAbletonLink() {
        abletonLinkClock.onBeat = { [weak self] event in
            DispatchQueue.main.async {
                self?.handleBeatTick(event.kind)
            }
        }

        abletonLinkClock.onStatusUpdate = { [weak self] status in
            DispatchQueue.main.async {
                self?.handleAbletonLinkStatus(status)
            }
        }

        abletonLinkClock.start()
        abletonLinkClock.setEnabled(abletonLinkEnabled)
    }

    private func updateStatusItemMenu() {
        let menu = NSMenu()

        let abletonLinkItem = menu.addItem(withTitle: "Use Ableton Link", action: #selector(toggleAbletonLink), keyEquivalent: "")
        abletonLinkItem.target = self
        abletonLinkItem.state = abletonLinkEnabled ? .on : .off
        abletonLinkMenu = abletonLinkItem

        let peersItem = menu.addItem(withTitle: "Link Peers: \(latestAbletonLinkStatus?.peerCount ?? 0)", action: nil, keyEquivalent: "")
        peersItem.isEnabled = false
        abletonLinkPeersMenu = peersItem

        menu.addItem(.separator())

        let bpmItem = menu.addItem(withTitle: "Show BPM", action: #selector(toggleBPMMenu), keyEquivalent: "")
        bpmItem.target = self
        bpmItem.state = showBPM ? .on : .off
        bpmMenu = bpmItem

        let accentItem = menu.addItem(withTitle: "Downbeat Accent", action: nil, keyEquivalent: "")
        let accentMenu = NSMenu()
        downbeatAccentMenuItems = [:]
        for mode in DownbeatAccentMode.allCases {
            let item = accentMenu.addItem(withTitle: mode.title, action: #selector(selectDownbeatAccentMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = mode == downbeatAccentMode ? .on : .off
            downbeatAccentMenuItems[mode] = item
        }
        menu.setSubmenu(accentMenu, for: accentItem)

        menu.addItem(.separator())

        let testHapticItem = menu.addItem(withTitle: "Test Haptic in 2s", action: #selector(testHapticFeedback), keyEquivalent: "")
        testHapticItem.target = self

        let diagnosticsItem = menu.addItem(withTitle: "Open Haptic Diagnostics", action: #selector(openHapticDiagnostics), keyEquivalent: "")
        diagnosticsItem.target = self

        let helpItem = menu.addItem(withTitle: "Help", action: #selector(showHelpModal), keyEquivalent: "")
        helpItem.target = self

        let quitItem = menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quitItem.target = NSApp

        statusItem?.menu = menu
    }

    @objc private func toggleAbletonLink() {
        abletonLinkEnabled.toggle()
        UserDefaults.standard.set(abletonLinkEnabled, forKey: abletonLinkEnabledKey)
        abletonLinkMenu?.state = abletonLinkEnabled ? .on : .off
        abletonLinkClock.setEnabled(abletonLinkEnabled)

        if !abletonLinkEnabled {
            resetClock()
        }
    }

    @objc private func toggleBPMMenu() {
        showBPM.toggle()
        UserDefaults.standard.set(showBPM, forKey: showBPMKey)
        bpmMenu?.state = showBPM ? .on : .off
    }

    @objc private func selectDownbeatAccentMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = DownbeatAccentMode(rawValue: rawValue) else {
            return
        }

        downbeatAccentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: downbeatAccentModeKey)
        updateDownbeatAccentMenu()
    }

    private func updateDownbeatAccentMenu() {
        for (mode, item) in downbeatAccentMenuItems {
            item.state = mode == downbeatAccentMode ? .on : .off
        }
    }

    @objc private func testHapticFeedback() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.performHapticBurst()
        }
    }

    @objc private func openHapticDiagnostics() {
        let window = diagnosticsWindow ?? makeDiagnosticsWindow()
        diagnosticsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func renderBPM(_ timer: Timer) {
        let displayBPM = abletonLinkEnabled ? latestAbletonLinkStatus?.tempo ?? 0 : bpm

        if displayBPM > 0 && showBPM {
            statusItem?.button?.title = formatter.string(from: NSNumber(value: displayBPM)) ?? ""
        } else {
            statusItem?.button?.title = ""
        }
    }

    fileprivate func resetStatusIconTimer() {
        DispatchQueue.main.async { [weak self] in
            Timer.scheduledTimer(
                timeInterval: 0.06,
                target: self as Any,
                selector: #selector(AppDelegate.resetStatusIcon(_:)),
                userInfo: nil,
                repeats: false
            )
        }
    }

    @objc private func resetStatusIcon(_ timer: Timer) {
        statusItem?.button?.image = notic
    }

    fileprivate func handleBeatTick(_ kind: BeatKind = .regular) {
        performHapticFeedback(kind)

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.statusItem?.button?.image = self.tic
            self.resetStatusIconTimer()
        }
    }

    private func handleAbletonLinkStatus(_ status: AbletonLinkStatus) {
        latestAbletonLinkStatus = status
        abletonLinkPeersMenu?.title = "Link Peers: \(status.peerCount)"
    }

    private func performHapticFeedback(_ kind: BeatKind) {
        guard kind == .downbeat else {
            performHapticPattern(.levelChange)
            return
        }

        switch downbeatAccentMode {
        case .off:
            performHapticPattern(.levelChange)
        case .light:
            performHapticPattern(.generic)
        case .strong:
            performHapticPattern(.levelChange)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                self.performHapticPattern(.alignment)
            }
        }
    }

    private func performHapticPattern(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }

    private func performHapticBurst() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }

    private func makeDiagnosticsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Haptic Diagnostics"
        window.center()

        let contentView = NSView(frame: window.contentView?.bounds ?? .zero)
        contentView.autoresizingMask = [.width, .height]

        let button = HapticTestButton(frame: NSRect(x: 80, y: 70, width: 200, height: 44))
        button.title = "Press for Haptic"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(testHapticFeedback)
        button.autoresizingMask = []

        let label = NSTextField(labelWithString: "Press and hold the button with the trackpad.")
        label.alignment = .center
        label.frame = NSRect(x: 30, y: 125, width: 300, height: 22)

        contentView.addSubview(label)
        contentView.addSubview(button)
        window.contentView = contentView

        return window
    }

    fileprivate func resetClock() {
        clockCount = beatTicks
        midiBeatIndex = 0
        bpm = 0

        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.title = ""
        }
    }
}

private final class HapticTestButton: NSButton {
    override func mouseDown(with event: NSEvent) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        super.mouseDown(with: event)
    }
}

private func midiInputCallback(
    _ packetList: UnsafePointer<MIDIPacketList>,
    _ procRef: UnsafeMutableRawPointer?,
    _ srcRef: UnsafeMutableRawPointer?
) {
    guard let procRef else {
        return
    }

    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(procRef).takeUnretainedValue()
    var packet = packetList.pointee.packet

    for _ in 0..<packetList.pointee.numPackets {
        parseMIDIPacket(packet, byteCount: Int(packet.length), appDelegate: appDelegate)
        let nextPacket = withUnsafePointer(to: packet) { packetPointer in
            MIDIPacketNext(packetPointer).pointee
        }
        packet = nextPacket
    }
}

private func parseMIDIPacket(_ packet: MIDIPacket, byteCount: Int, appDelegate: AppDelegate) {
    withUnsafeBytes(of: packet.data) { rawBytes in
        let bytes = rawBytes.bindMemory(to: UInt8.self)
        var byteIndex = 0

        while byteIndex < byteCount {
            let status = bytes[byteIndex]
            let size = midiMessageSize(for: status)

            switch status {
            case 0xF8:
                processClockTick(packet: packet, appDelegate: appDelegate)
            case 0xFC:
                appDelegate.resetClock()
            default:
                break
            }

            byteIndex += size
        }
    }
}

private func midiMessageSize(for status: UInt8) -> Int {
    if status < 0xC0 {
        return 3
    } else if status < 0xE0 {
        return 2
    } else if status < 0xF3 {
        return 3
    } else if status == 0xF3 {
        return 2
    } else {
        return 1
    }
}

private func processClockTick(packet: MIDIPacket, appDelegate: AppDelegate) {
    guard !appDelegate.abletonLinkEnabled else {
        return
    }

    appDelegate.previousClockTime = appDelegate.currentClockTime
    appDelegate.currentClockTime = Double(packet.timeStamp)

    if appDelegate.previousClockTime > 0 && appDelegate.currentClockTime > 0 {
        let measuredTickDelta = appDelegate.currentClockTime - appDelegate.previousClockTime

        if appDelegate.tickDelta == 0 {
            appDelegate.tickDelta = measuredTickDelta
        } else {
            appDelegate.tickDelta = (measuredTickDelta * smoothingFactor) + (appDelegate.tickDelta * (1.0 - smoothingFactor))

            var timebaseInfo = mach_timebase_info_data_t()
            mach_timebase_info(&timebaseInfo)

            let oneThousand = 1_000.0
            appDelegate.intervalInNanoseconds = (appDelegate.tickDelta * Double(timebaseInfo.numer)) / (oneThousand * Double(timebaseInfo.denom))

            let newBPM = (1_000_000 / appDelegate.intervalInNanoseconds / Double(beatTicks)) * 60
            appDelegate.bpm = (newBPM * smoothingFactor) + (appDelegate.bpm * (1.0 - smoothingFactor))
        }
    }

    if appDelegate.clockCount % beatTicks == 0 {
        appDelegate.clockCount = 0
        let beatKind: BeatKind = appDelegate.midiBeatIndex % beatsPerBar == 0 ? .downbeat : .regular
        appDelegate.midiBeatIndex += 1
        appDelegate.handleBeatTick(beatKind)
    }

    appDelegate.clockCount += 1
}
