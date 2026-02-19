import AppKit
import CoreGraphics
import Foundation

// MARK: - Config

struct AppConfig: Codable {
    var scrollAmount: Int?
    var continuousSpeed: Int?
}

struct ScrollDefaults: Codable {
    var scrollAmount: Int
    var continuousSpeed: Int
    var mouseXRatio: Double
    var mouseYRatio: Double
    var continuousIntervalMs: Int
    var holdThresholdMs: Int
}

struct Config: Codable {
    var defaults: ScrollDefaults
    var apps: [String: AppConfig]
}

let pidPath = "/tmp/smooth-scroller.pid"

let defaultConfig = Config(
    defaults: ScrollDefaults(
        scrollAmount: 400,
        continuousSpeed: 5,
        mouseXRatio: 0.75,
        mouseYRatio: 0.5,
        continuousIntervalMs: 16,
        holdThresholdMs: 500
    ),
    apps: [:]
)

func loadConfig() -> Config {
    let path = NSString(string: "~/.config/smooth-scroller/config.json").expandingTildeInPath
    guard let data = FileManager.default.contents(atPath: path) else { return defaultConfig }
    return (try? JSONDecoder().decode(Config.self, from: data)) ?? defaultConfig
}

// MARK: - Window & Mouse

func getActiveWindowBounds() -> CGRect? {
    guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
    let pid = app.processIdentifier
    guard let list = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
    ) as? [[String: Any]] else { return nil }

    for win in list {
        guard let ownerPID = win[kCGWindowOwnerPID as String] as? pid_t,
              ownerPID == pid,
              let boundsRef = win[kCGWindowBounds as String]
        else { continue }

        let cfDict = boundsRef as! CFDictionary
        var rect = CGRect.zero
        guard CGRectMakeWithDictionaryRepresentation(cfDict, &rect),
              rect.width > 50, rect.height > 50 else { continue }
        return rect
    }
    return nil
}

func moveMouseToWindow(bounds: CGRect, config: Config) {
    let x = bounds.origin.x + bounds.width * config.defaults.mouseXRatio
    let y = bounds.origin.y + bounds.height * config.defaults.mouseYRatio
    CGWarpMouseCursorPosition(CGPoint(x: x, y: y))
}

// MARK: - Scroll

func sendScroll(delta: Int32) {
    guard let event = CGEvent(
        scrollWheelEvent2Source: nil, units: .pixel,
        wheelCount: 1, wheel1: delta, wheel2: 0, wheel3: 0
    ) else { return }
    event.post(tap: .cghidEventTap)
}

func resolveScrollAmount(bundleId: String?, config: Config) -> Int {
    if let bid = bundleId, let app = config.apps[bid], let amt = app.scrollAmount {
        return amt
    }
    return config.defaults.scrollAmount
}

func resolveContinuousSpeed(bundleId: String?, config: Config) -> Int {
    if let bid = bundleId, let app = config.apps[bid], let spd = app.continuousSpeed {
        return spd
    }
    return config.defaults.continuousSpeed
}

// MARK: - PID

func writePid() {
    try? "\(ProcessInfo.processInfo.processIdentifier)".write(
        toFile: pidPath, atomically: true, encoding: .utf8
    )
}

func removePid() {
    try? FileManager.default.removeItem(atPath: pidPath)
}

// MARK: - Commands

func stopScroll() {
    guard let str = try? String(contentsOfFile: pidPath, encoding: .utf8),
          let pid = pid_t(str.trimmingCharacters(in: .whitespacesAndNewlines))
    else { return }
    kill(pid, SIGTERM)
    removePid()
}

func startScroll(direction: String) {
    stopScroll()

    let config = loadConfig()
    let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    let isUp = direction == "up"

    // Move mouse into window
    if let bounds = getActiveWindowBounds() {
        moveMouseToWindow(bounds: bounds, config: config)
    }

    // Immediate half-page scroll
    let amount = resolveScrollAmount(bundleId: bundleId, config: config)
    sendScroll(delta: isUp ? Int32(amount) : -Int32(amount))

    // Write PID for stop command
    writePid()

    // SIGTERM handler
    signal(SIGTERM) { _ in
        removePid()
        exit(0)
    }

    // Wait for hold threshold before starting continuous scroll
    usleep(UInt32(config.defaults.holdThresholdMs) * 1000)

    // Continuous scroll loop
    let speed = resolveContinuousSpeed(bundleId: bundleId, config: config)
    let delta = isUp ? Int32(speed) : -Int32(speed)
    let interval = UInt32(config.defaults.continuousIntervalMs) * 1000

    while true {
        sendScroll(delta: delta)
        usleep(interval)
    }
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count >= 2 else {
    fputs("Usage: smooth-scroller <start <up|down>|stop>\n", stderr)
    exit(1)
}

switch args[1] {
case "start":
    guard args.count >= 3, ["up", "down"].contains(args[2]) else {
        fputs("Usage: smooth-scroller start <up|down>\n", stderr)
        exit(1)
    }
    startScroll(direction: args[2])
case "stop":
    stopScroll()
default:
    fputs("Unknown command: \(args[1])\n", stderr)
    exit(1)
}
