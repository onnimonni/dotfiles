import AppKit
import CoreGraphics
import Foundation

// MARK: - Config

struct AppConfig: Codable {
    var initialSpeed: Double?
    var maxSpeed: Double?
}

struct ScrollDefaults: Codable {
    var initialSpeed: Double  // px per 8ms tick. 0 = auto from windowHeight/4 over 250ms
    var maxSpeed: Double      // px per 8ms tick cap
    var acceleration: Double  // multiplier per tick (e.g. 0.002 = 0.2% speed increase per 8ms)
    var coastMs: Double       // ms to scroll at initial speed before acceleration begins
    var mouseXRatio: Double
    var mouseYRatio: Double
}

struct Config: Codable {
    var defaults: ScrollDefaults
    var apps: [String: AppConfig]
}

let pidPath = "/tmp/smooth-scroller.pid"

let defaultConfig = Config(
    defaults: ScrollDefaults(
        initialSpeed: 0,
        maxSpeed: 48.0,
        acceleration: 0.002,
        coastMs: 800,
        mouseXRatio: 0.75,
        mouseYRatio: 0.5
    ),
    apps: [:]
)

func loadConfig() -> Config {
    let path = NSString(string: "~/.config/smooth-scroller/config.json").expandingTildeInPath
    guard let data = FileManager.default.contents(atPath: path) else { return defaultConfig }
    return (try? JSONDecoder().decode(Config.self, from: data)) ?? defaultConfig
}

// MARK: - Global state

var terminated: sig_atomic_t = 0

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
    event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
    event.post(tap: .cghidEventTap)
}

/// Calculate initial speed: cover 1/4 window height in ~250ms at 8ms ticks.
/// Returns px/tick. Falls back to 8.0 if window bounds unavailable.
func calcAutoSpeed(windowBounds: CGRect?) -> Double {
    let height = windowBounds?.height ?? 900
    let quarterPage = height / 4
    let ticksPer250ms = 250.0 / 8.0  // ~31 ticks
    return Double(quarterPage) / ticksPer250ms
}

func resolveInitialSpeed(bundleId: String?, windowBounds: CGRect?, config: Config) -> Double {
    if let bid = bundleId, let app = config.apps[bid], let v = app.initialSpeed, v > 0 {
        return v
    }
    if config.defaults.initialSpeed > 0 {
        return config.defaults.initialSpeed
    }
    return calcAutoSpeed(windowBounds: windowBounds)
}

func resolveMaxSpeed(bundleId: String?, config: Config) -> Double {
    if let bid = bundleId, let app = config.apps[bid], let v = app.maxSpeed {
        return v
    }
    return config.defaults.maxSpeed
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

    // Move mouse into active window
    let windowBounds = getActiveWindowBounds()
    if let bounds = windowBounds {
        moveMouseToWindow(bounds: bounds, config: config)
    }

    writePid()
    signal(SIGTERM) { _ in terminated = 1 }

    // Scroll immediately — no delay. Speed auto-calculated to cover 1/4 page in ~250ms.
    let intervalUs: UInt32 = 8000  // 8ms ≈ 120fps
    let intervalMs = Double(intervalUs) / 1000.0
    var speed = resolveInitialSpeed(bundleId: bundleId, windowBounds: windowBounds, config: config)
    let maxSpeed = resolveMaxSpeed(bundleId: bundleId, config: config)
    let accelFactor = config.defaults.acceleration  // multiplicative: speed *= (1 + factor)
    let coastTicks = Int(config.defaults.coastMs / intervalMs)  // ticks at constant speed

    // Log effective config to stderr for tuning
    fputs("smooth-scroller: speed=\(String(format: "%.1f", speed)) max=\(String(format: "%.1f", maxSpeed)) accel=\(String(format: "%.4f", accelFactor)) coast=\(coastTicks) ticks window=\(windowBounds?.height ?? 0)h\n", stderr)

    var tick = 0
    while terminated == 0 {
        let d = Int32(round(speed))
        if d != 0 { sendScroll(delta: isUp ? d : -d) }
        tick += 1
        if tick > coastTicks {
            speed = min(speed * (1.0 + accelFactor), maxSpeed)
        }
        usleep(intervalUs)
    }

    removePid()
    exit(0)
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
