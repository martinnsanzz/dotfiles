// raise-windows: brings windows that programs started from a terminal open
// (pygame, tkinter, matplotlib, `make run`, F5 in VS Code) to the front.
//
// Why it's needed: macOS only lets the app you're using hand focus to another
// one. A python3 started from Ghostty opens its window, asks for focus, and
// macOS says no because Ghostty is the active app. So the window lands behind
// Ghostty.
//
// What it does: macOS posts a notice every time an app starts. A program that
// opens a window becomes an "app" at that moment (python3 shows up in the Dock
// as "Python"). For each new app, this checks whether it was started from a
// terminal (one of its parent processes is tmux, vim, a shell, Ghostty...),
// waits for its first window, and then activates it with all its windows.
// Apps opened from the Dock, Spotlight or Finder are started by launchd, not a
// terminal, so they're left alone.
//
// It needs no permissions: activating an app is allowed for any program, and
// it only reads which process owns which window, not what's in it.
//
// install.sh compiles it to ~/.local/bin/raise-windows and starts it at login
// with a LaunchAgent. `raise-windows -v` runs it in the foreground and prints
// what it sees.

import AppKit
import Darwin

// Process names that mean "started from a terminal".
let terminalParents: Set<String> = [
    "ghostty", "tmux", "vim", "fish", "zsh", "bash", "sh", "make",
    "Terminal", "iTerm2",
]
let windowTimeout = 30.0  // seconds to wait for the first window
let verbose = CommandLine.arguments.contains("-v")

func log(_ items: Any...) {
    guard verbose else { return }
    print(items.map { "\($0)" }.joined(separator: " "))
    fflush(stdout)
}

/// A process's parent pid and name, from the kernel.
func processInfo(_ pid: pid_t) -> (parent: pid_t, name: String)? {
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
    let name = withUnsafeBytes(of: info.pbi_comm) {
        String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
    }
    return (pid_t(info.pbi_ppid), name)
}

/// True if a parent, grandparent... of pid is a terminal, shell or editor.
func startedFromTerminal(_ pid: pid_t) -> Bool {
    var current = processInfo(pid)?.parent ?? 1
    for _ in 0..<30 {  // 30 levels is plenty and stops any loop
        guard current > 1, let info = processInfo(current) else { return false }
        if terminalParents.contains(info.name) { return true }
        current = info.parent
    }
    return false
}

/// True once pid has a normal window on screen.
func hasWindow(_ pid: pid_t) -> Bool {
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
        as? [[String: Any]] ?? []
    return windows.contains {
        ($0[kCGWindowOwnerPID as String] as? pid_t) == pid
            && ($0[kCGWindowLayer as String] as? Int) == 0
    }
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
) { note in
    guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    else { return }
    let pid = app.processIdentifier
    let name = app.localizedName ?? "pid \(pid)"
    guard startedFromTerminal(pid) else {
        log("ignored", name, "(not from a terminal)")
        return
    }
    let started = Date()
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        if app.isTerminated || Date().timeIntervalSince(started) > windowTimeout {
            timer.invalidate()
            log("gave up on", name, "(no window)")
        } else if hasWindow(pid) {
            timer.invalidate()
            let ok = app.activate(options: [.activateAllWindows])
            log(ok ? "raised" : "couldn't raise", name)
        }
    }
}

log("watching for apps started from a terminal")
RunLoop.main.run()
