import Carbon
import Foundation

let targetID = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "org.unknown.keylayout.ONNIDVORAK-QWERTYCMD"

// Register keyboard layouts from ~/Library/Keyboard Layouts/ so macOS
// discovers newly deployed .keylayout files without requiring a reboot.
let layoutDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Keyboard Layouts")
TISRegisterInputSource(layoutDir as CFURL)

guard let sourceList = TISCreateInputSourceList(nil, true)?
    .takeRetainedValue() as? [TISInputSource] else {
    fputs("Failed to get input source list\n", stderr)
    exit(1)
}

for source in sourceList {
    guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
    let sourceID = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String

    if sourceID == targetID {
        let e = TISEnableInputSource(source)
        let s = TISSelectInputSource(source)
        if e != noErr || s != noErr {
            fputs("Failed to activate \(targetID) (enable=\(e) select=\(s))\n", stderr)
            exit(1)
        }
        print("Activated: \(targetID)")
        exit(0)
    }
}

fputs("Input source '\(targetID)' not found. A reboot may be needed.\n", stderr)
exit(1)
