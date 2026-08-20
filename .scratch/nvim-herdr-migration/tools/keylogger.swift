// Zed keybind logger — time-boxed, privacy-scoped.
//
// Logs keyDown events to a file, but ONLY while the frontmost app's bundle id
// contains the filter string (default "zed"). This captures the user's actual
// keybinds while they work in Zed, without recording anything typed anywhere
// else.
//
// Usage:
//   swiftc keylogger.swift -o keylogger
//   ./keylogger [output-path] [app-filter]
//
//   output-path  where to append events (default ./zed-keys.log)
//   app-filter   substring matched (case-insensitive) against the frontmost
//                app's bundle id (default "zed")
//
// Requires Accessibility (Input Monitoring) permission for the terminal that
// runs it: System Settings → Privacy & Security → Input Monitoring (or
// Accessibility), add the terminal, then relaunch it.
//
// Output format per line:
//   <unix-ts> <bundle-id> <key> <modifiers> repeat=<0|1>

import Cocoa
import CoreGraphics
import Foundation

func keyName(_ code: Int64) -> String {
    switch code {
    case 0: return "a"; case 1: return "s"; case 2: return "d"; case 3: return "f"
    case 4: return "h"; case 5: return "g"; case 6: return "z"; case 7: return "x"
    case 8: return "c"; case 9: return "v"; case 11: return "b"; case 12: return "q"
    case 13: return "w"; case 14: return "e"; case 15: return "r"; case 16: return "y"
    case 17: return "t"; case 18: return "1"; case 19: return "2"; case 20: return "3"
    case 21: return "4"; case 22: return "6"; case 23: return "5"; case 24: return "="
    case 25: return "9"; case 26: return "7"; case 27: return "-"; case 28: return "8"
    case 29: return "0"; case 30: return "]"; case 31: return "o"; case 32: return "u"
    case 33: return "["; case 34: return "i"; case 35: return "p"; case 36: return "return"
    case 37: return "l"; case 38: return "j"; case 39: return "'"; case 40: return "k"
    case 41: return ";"; case 42: return "\\"; case 43: return ","; case 44: return "/"
    case 45: return "n"; case 46: return "m"; case 47: return "."; case 48: return "tab"
    case 49: return "space"; case 50: return "`"; case 51: return "delete"
    case 53: return "esc"; case 54: return "right-cmd"; case 55: return "left-cmd"
    case 56: return "left-shift"; case 57: return "caps"; case 58: return "left-opt"
    case 59: return "left-ctrl"; case 60: return "right-shift"; case 61: return "right-opt"
    case 62: return "right-ctrl"; case 63: return "fn"
    case 65: return "kp-."; case 67: return "kp-*"; case 69: return "kp-+"
    case 71: return "clear"; case 76: return "kp-enter"; case 78: return "kp--"
    case 81: return "kp-="; case 82: return "kp-0"; case 83: return "kp-1"
    case 84: return "kp-2"; case 85: return "kp-3"; case 86: return "kp-4"
    case 87: return "kp-5"; case 88: return "kp-6"; case 89: return "kp-7"
    case 91: return "kp-8"; case 92: return "kp-9"
    case 96: return "f5"; case 97: return "f6"; case 98: return "f7"; case 99: return "f3"
    case 100: return "f8"; case 101: return "f9"; case 102: return "f11"; case 103: return "f13"
    case 105: return "f14"; case 106: return "f10"; case 107: return "f12"; case 109: return "f15"
    case 111: return "f16"; case 113: return "f17"; case 114: return "f18"; case 115: return "f19"
    case 116: return "f20"; case 117: return "forward-delete"; case 118: return "f4"
    case 119: return "f2"; case 120: return "f1"
    case 123: return "left"; case 124: return "right"; case 125: return "down"; case 126: return "up"
    default: return "keycode(\(code))"
    }
}

func modifiers(_ flags: UInt64) -> String {
    var parts: [String] = []
    if flags & 0x00100000 != 0 { parts.append("cmd") }
    if flags & 0x00040000 != 0 { parts.append("ctrl") }
    if flags & 0x00080000 != 0 { parts.append("opt") }
    if flags & 0x00020000 != 0 { parts.append("shift") }
    if flags & 0x00800000 != 0 { parts.append("fn") }
    if flags & 0x00010000 != 0 { parts.append("caps") }
    return parts.joined(separator: "+")
}

// Globals (not locals) so the C function pointer callback can reference them
// without capturing context.
let lock = NSLock()
var appFilterLower = "zed"
var outFile: FileHandle!

let args = CommandLine.arguments
let outputPath = args.count > 1 ? args[1] : "zed-keys.log"
appFilterLower = (args.count > 2 ? args[2] : "zed").lowercased()

if !FileManager.default.fileExists(atPath: outputPath) {
    FileManager.default.createFile(atPath: outputPath, contents: nil)
}
guard let fh = FileHandle(forWritingAtPath: outputPath) else {
    FileHandle.standardError.write("cannot open \(outputPath)\n".data(using: .utf8)!)
    exit(1)
}
outFile = fh
outFile.seekToEndOfFile()

let callback: CGEventTapCallBack = { _, type, event, _ in
    guard type == .keyDown else { return Unmanaged.passUnretained(event) }
    let app = NSWorkspace.shared.frontmostApplication
    let appId = app?.bundleIdentifier ?? app?.localizedName ?? "unknown"
    guard appId.lowercased().contains(appFilterLower) else { return Unmanaged.passUnretained(event) }
    let keycode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags.rawValue
    let autorepeat = event.getIntegerValueField(.keyboardEventAutorepeat)
    let ts = String(format: "%.3f", Date().timeIntervalSince1970)
    let line = "\(ts) \(appId) \(keyName(keycode)) \(modifiers(flags)) repeat=\(autorepeat)"
    lock.lock()
    if let data = (line + "\n").data(using: .utf8) { outFile.write(data) }
    lock.unlock()
    return Unmanaged.passUnretained(event)
}

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
    callback: callback,
    userInfo: nil
) else {
    FileHandle.standardError.write(
        "Failed to create event tap. Grant Input Monitoring/Accessibility to the terminal running this, then retry.\n"
            .data(using: .utf8)!
    )
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

FileHandle.standardError.write(
    "Keylogger running — appending to \(outputPath) (filter: '\(appFilterLower)'). Ctrl+C to stop.\n"
        .data(using: .utf8)!
)
CFRunLoopRun()
