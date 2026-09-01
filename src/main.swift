import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let button = statusItem.button else { return }
        button.image = Self.idleIcon
        button.toolTip = "Copy Save — click to save the clipboard image to the Desktop"
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Left-click saves straight away; right- or control-click opens the menu.
    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        guard wantsMenu else { return save() }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(withTitle: "Save Clipboard Image", action: #selector(save), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Copy Save", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.items.forEach { $0.target = $0.action == #selector(NSApplication.terminate(_:)) ? NSApp : self }
        return menu
    }()

    @objc private func save() {
        guard let image = NSImage(pasteboard: .general) else {
            return report("No image on the clipboard.", "Copy an image, then click the Copy Save icon.")
        }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            return report("Could not encode that image.", nil)
        }

        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        let url = desktop.appendingPathComponent("Clipboard \(Self.formatter.string(from: Date())).png")
        do {
            try png.write(to: url)
            flash(Self.savedIcon)
        } catch {
            report("Could not save to the Desktop.", error.localizedDescription)
        }
    }

    /// A success is a 1.5s checkmark in the menu bar; a failure needs words, and
    /// with no window there is nowhere else to put them.
    private func report(_ message: String, _ detail: String?) {
        flash(Self.failedIcon)
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail ?? ""
        alert.alertStyle = .warning
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func flash(_ image: NSImage?) {
        statusItem.button?.image = image
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.statusItem.button?.image = Self.idleIcon
        }
    }

    private static func icon(_ symbol: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Copy Save")
        image?.isTemplate = true
        return image
    }
    private static let idleIcon = icon("photo.on.rectangle")
    private static let savedIcon = icon("checkmark.circle.fill")
    private static let failedIcon = icon("exclamationmark.triangle.fill")

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss.SSS"
        return f
    }()
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
