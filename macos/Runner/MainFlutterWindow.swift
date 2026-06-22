import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  // Fix 1: macOS 26 (Tahoe) key-window bug — text fields are non-reactive
  // without this override.
  override var canBecomeKey: Bool { true }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Fix 2: Enforce minimum window size, clear stale autosaved frame, center.
    self.setFrameAutosaveName("")
    let minSize = NSSize(width: 1280, height: 720)
    self.minSize = minSize
    if self.frame.width < minSize.width || self.frame.height < minSize.height {
      self.setFrame(NSRect(origin: self.frame.origin, size: minSize), display: true)
    }
    self.center()

    // Fix 3: NSOpenPanel steals first responder and never returns it.
    // Re-assert first responder every time the window becomes key.
    NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeKeyNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      self?.makeFirstResponder(self?.contentViewController?.view)
    }

    super.awakeFromNib()
  }
}
