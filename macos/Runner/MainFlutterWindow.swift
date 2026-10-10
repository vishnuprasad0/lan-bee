import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Same size as on Windows; below the minimum the chat layout breaks.
    self.title = "LAN Bee"
    self.setContentSize(NSSize(width: 1100, height: 720))
    self.contentMinSize = NSSize(width: 420, height: 560)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
