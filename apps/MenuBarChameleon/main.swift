import AppKit
import ScreenCaptureKit
import CoreMedia
import VideoToolbox
import os.log

private let log = OSLog(subsystem: "build.flaky.MenuBarChameleon", category: "main")
private func logMsg(_ msg: String) {
    os_log("%{public}@", log: log, type: .default, msg)
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(msg)\n"
    if let data = line.data(using: .utf8) {
        let fh = FileHandle(forWritingAtPath: "/tmp/MenuBarChameleon.log")
            ?? { FileManager.default.createFile(atPath: "/tmp/MenuBarChameleon.log", contents: nil)
                 return FileHandle(forWritingAtPath: "/tmp/MenuBarChameleon.log")! }()
        fh.seekToEndOfFile()
        fh.write(data)
        fh.closeFile()
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, SCStreamDelegate, SCStreamOutput {
    private var statusItem: NSStatusItem!
    private var stream: SCStream?
    private let processingQueue = DispatchQueue(label: "chameleon", qos: .utility)
    private var permissionTimer: Timer?
    private var enabled = true
    private var streamRunning = false

    // Wallpaper state
    private var originalWallpaperURL: URL?
    private var originalWallpaperOptions: [NSWorkspace.DesktopImageOptionKey: Any]?
    private var cachedWallpaper: CGImage?
    private var menuBarFraction: Double = 0.04
    private var useFileA = true
    private let tempA = URL(fileURLWithPath: "/tmp/MenuBarChameleon_a.jpg")
    private let tempB = URL(fileURLWithPath: "/tmp/MenuBarChameleon_b.jpg")
    private let savedOriginalPath = "/tmp/MenuBarChameleon_original.txt"
    private var lastUpdate = Date.distantPast
    private var lastStripAvgR: Double = -1
    private var lastStripAvgG: Double = -1
    private var lastStripAvgB: Double = -1

    func applicationDidFinishLaunching(_ notification: Notification) {
        logMsg("App launched, bundle: \(Bundle.main.bundleIdentifier ?? "?")")
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        cacheOriginalWallpaper()

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkPermissionAndStart()
        }
        checkPermissionAndStart()
    }

    func applicationWillTerminate(_ notification: Notification) {
        restoreOriginalWallpaper()
    }

    // MARK: Wallpaper

    private func cacheOriginalWallpaper() {
        guard let screen = NSScreen.main else { return }

        // Check if we crashed last time and left a temp wallpaper
        if let saved = try? String(contentsOfFile: savedOriginalPath, encoding: .utf8) {
            let url = URL(fileURLWithPath: saved.trimmingCharacters(in: .whitespacesAndNewlines))
            if FileManager.default.fileExists(atPath: url.path) {
                originalWallpaperURL = url
            }
        }

        // Get current wallpaper
        if originalWallpaperURL == nil {
            originalWallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen)
        }
        originalWallpaperOptions = NSWorkspace.shared.desktopImageOptions(for: screen)

        guard let url = originalWallpaperURL else { return }

        // Save original path so we can restore after a crash
        try? url.path.write(toFile: savedOriginalPath, atomically: true, encoding: .utf8)

        // Load into memory
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return }
        cachedWallpaper = img

        let mbH = screen.frame.maxY - screen.visibleFrame.maxY
        menuBarFraction = Double(mbH) / Double(screen.frame.height)
    }

    private func restoreOriginalWallpaper() {
        guard let url = originalWallpaperURL, let screen = NSScreen.main else { return }
        try? NSWorkspace.shared.setDesktopImageURL(
            url, for: screen, options: originalWallpaperOptions ?? [:]
        )
        try? FileManager.default.removeItem(at: tempA)
        try? FileManager.default.removeItem(at: tempB)
        try? FileManager.default.removeItem(atPath: savedOriginalPath)
    }

    // MARK: Permission

    private func checkPermissionAndStart() {
        guard !streamRunning, enabled else { return }
        let hasPerm = CGPreflightScreenCaptureAccess()
        logMsg("Permission check: \(hasPerm)")
        guard hasPerm else { return }
        permissionTimer?.invalidate()
        permissionTimer = nil
        Task { await startStream() }
    }

    // MARK: SCStream

    private func startStream() async {
        guard let screen = NSScreen.main else { return }
        let mbH = screen.frame.maxY - screen.visibleFrame.maxY
        guard mbH > 0 else { return }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true
            )
            guard let screenID = screen.deviceDescription[
                      NSDeviceDescriptionKey("NSScreenNumber")
                  ] as? CGDirectDisplayID,
                  let scDisplay = content.displays.first(where: {
                      $0.displayID == screenID
                  }) else { return }

            let selfApp = content.applications.first {
                $0.bundleIdentifier == Bundle.main.bundleIdentifier
            }
            let excludeApps: [SCRunningApplication] = selfApp.map { [$0] } ?? []
            let filter = SCContentFilter(
                display: scDisplay,
                excludingApplications: excludeApps,
                exceptingWindows: []
            )

            let config = SCStreamConfiguration()
            config.sourceRect = CGRect(
                x: 0, y: mbH,
                width: CGFloat(scDisplay.width), height: 6
            )
            config.width = 256
            config.height = 2
            config.showsCursor = false
            config.minimumFrameInterval = CMTime(value: 1, timescale: 2) // 2 fps max
            config.queueDepth = 2

            stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: processingQueue)
            try await stream?.startCapture()
            streamRunning = true
            logMsg("Stream started, sourceRect: \(config.sourceRect), wallpaper: \(cachedWallpaper.map { "\($0.width)x\($0.height)" } ?? "nil")")
        } catch {
            streamRunning = false
            logMsg("Stream error: \(error)")
            if permissionTimer == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.permissionTimer = Timer.scheduledTimer(
                        withTimeInterval: 10, repeats: true
                    ) { [weak self] _ in
                        self?.checkPermissionAndStart()
                    }
                }
            }
        }
    }

    /// Compute average RGB of a CGImage (returns values 0-255)
    private func averageColor(of img: CGImage) -> (r: Double, g: Double, b: Double)? {
        let w = img.width, h = img.height
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        var rSum: UInt64 = 0, gSum: UInt64 = 0, bSum: UInt64 = 0
        let count = w * h
        for i in 0..<count {
            rSum += UInt64(ptr[i * 4])
            gSum += UInt64(ptr[i * 4 + 1])
            bSum += UInt64(ptr[i * 4 + 2])
        }
        let n = Double(count)
        return (Double(rSum) / n, Double(gSum) / n, Double(bSum) / n)
    }

    // SCStreamOutput — receives frames on processingQueue
    func stream(_ s: SCStream, didOutputSampleBuffer buf: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, enabled else { return }

        // Throttle to max 1 fps
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= 1.0 else { return }

        guard let pb = CMSampleBufferGetImageBuffer(buf) else { return }
        var raw: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pb, options: nil, imageOut: &raw)
        guard let strip = raw, let wallpaper = cachedWallpaper else { return }

        // Only update wallpaper if strip colors changed significantly
        if let avg = averageColor(of: strip) {
            let dr = abs(avg.r - lastStripAvgR)
            let dg = abs(avg.g - lastStripAvgG)
            let db = abs(avg.b - lastStripAvgB)
            let maxDiff = max(dr, max(dg, db))
            if maxDiff < 8 {  // less than ~3% change in any channel — skip
                return
            }
            lastStripAvgR = avg.r
            lastStripAvgG = avg.g
            lastStripAvgB = avg.b
            logMsg("Color changed: R=\(Int(avg.r)) G=\(Int(avg.g)) B=\(Int(avg.b)), delta=\(Int(maxDiff))")
        }

        lastUpdate = now

        // Composite color strip onto top of wallpaper
        guard let modified = compositeStrip(strip, onto: wallpaper) else { return }

        // Save to alternating temp files (different URL = instant swap)
        let target = useFileA ? tempA : tempB
        useFileA.toggle()

        guard let dest = CGImageDestinationCreateWithURL(
            target as CFURL, "public.jpeg" as CFString, 1, nil
        ) else { return }
        CGImageDestinationAddImage(dest, modified, [
            kCGImageDestinationLossyCompressionQuality: 0.92
        ] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return }

        // Set as wallpaper on main thread
        DispatchQueue.main.async {
            guard let screen = NSScreen.main else { return }
            try? NSWorkspace.shared.setDesktopImageURL(
                target, for: screen, options: self.originalWallpaperOptions ?? [:]
            )
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logMsg("Stream stopped: \(error)")
        streamRunning = false
        DispatchQueue.main.async { [weak self] in
            guard self?.permissionTimer == nil else { return }
            self?.permissionTimer = Timer.scheduledTimer(
                withTimeInterval: 10, repeats: true
            ) { [weak self] _ in
                self?.checkPermissionAndStart()
            }
        }
    }

    /// Replace the top strip of the wallpaper with sampled window colors.
    private func compositeStrip(_ strip: CGImage, onto wallpaper: CGImage) -> CGImage? {
        let w = wallpaper.width
        let h = wallpaper.height
        let stripH = max(1, Int(Double(h) * menuBarFraction * 1.5)) // slightly taller for good sampling

        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: wallpaper.bitsPerComponent,
            bytesPerRow: 0, // let CG calculate
            space: wallpaper.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Draw original wallpaper (CG origin = bottom-left)
        ctx.draw(wallpaper, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Draw color strip at TOP of image (top = y: h - stripH in CG coords)
        ctx.interpolationQuality = .high
        ctx.draw(strip, in: CGRect(x: 0, y: h - stripH, width: w, height: stripH))

        return ctx.makeImage()
    }

    // MARK: Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(
                systemSymbolName: "paintbrush.fill",
                accessibilityDescription: "MenuBarChameleon"
            )
        }

        let menu = NSMenu()

        let toggle = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: "e")
        toggle.target = self
        toggle.state = .on
        menu.addItem(toggle)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Restore Wallpaper & Quit",
                                action: #selector(quitAndRestore),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        enabled.toggle()
        sender.state = enabled ? .on : .off
        if !enabled {
            restoreOriginalWallpaper()
        } else {
            cacheOriginalWallpaper()
            checkPermissionAndStart()
        }
    }

    @objc private func quitAndRestore() {
        restoreOriginalWallpaper()
        NSApp.terminate(nil)
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
