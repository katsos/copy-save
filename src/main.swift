import AppKit

final class DropView: NSView {
    var onImage: ((NSImage) -> Void)?
    var onPaste: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL, .tiff, .png])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        readImage(from: sender.draggingPasteboard)
    }

    /// The app runs as a menu bar accessory, so it has no menu bar to carry key
    /// equivalents. The window handles its own.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command else { return false }
        switch event.charactersIgnoringModifiers {
        case "v": onPaste?()
        case "w": window?.close()
        case "q": NSApp.terminate(nil)
        default: return false
        }
        return true
    }

    @discardableResult
    func readImage(from pb: NSPasteboard) -> Bool {
        guard let image = NSImage(pasteboard: pb) else { return false }
        onImage?(image)
        return true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var dropView: DropView!
    private let status = NSTextField(labelWithString: "")
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Copy Save"
        window.center()

        dropView = DropView(frame: .zero)
        dropView.onImage = { [weak self] image in self?.save(image) }
        dropView.onPaste = { [weak self] in self?.paste(nil) }

        status.lineBreakMode = .byWordWrapping
        status.maximumNumberOfLines = 4
        status.translatesAutoresizingMaskIntoConstraints = false
        report("Click the menu bar icon to save a copied image",
               hint: "…or press ⌘V here, or drag an image onto this window.")

        dropView.addSubview(status)
        NSLayoutConstraint.activate([
            status.centerXAnchor.constraint(equalTo: dropView.centerXAnchor),
            status.centerYAnchor.constraint(equalTo: dropView.centerYAnchor),
            status.widthAnchor.constraint(lessThanOrEqualTo: dropView.widthAnchor, constant: -40),
        ])

        window.contentView = dropView
        showWindow()
    }

    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func paste(_ sender: Any?) {
        if !dropView.readImage(from: .general) {
            report("No image on the clipboard.", hint: "Copy an image, then click the menu bar icon.")
            flashStatusItem(Self.failedIcon)
        }
    }

    private func save(_ image: NSImage) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            report("Could not encode that image.", hint: "")
            flashStatusItem(Self.failedIcon)
            return
        }

        let url = desktop.appendingPathComponent("Clipboard \(Self.formatter.string(from: Date())).png")
        do {
            try png.write(to: url)
            report("Saved \(url.lastPathComponent)", hint: "Copy another image and click the menu bar icon again.")
            flashStatusItem(Self.savedIcon)
        } catch {
            report("Save failed.", hint: error.localizedDescription)
            flashStatusItem(Self.failedIcon)
        }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss.SSS"
        return f
    }()

    /// Two-tier centered text: message in medium 15pt, hint in secondary 11pt.
    private func report(_ message: String, hint: String) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 4
        let text = NSMutableAttributedString(string: message + (hint.isEmpty ? "" : "\n" + hint))
        text.addAttributes(
            [.font: NSFont.systemFont(ofSize: 15, weight: .medium),
             .foregroundColor: NSColor.labelColor,
             .paragraphStyle: style],
            range: NSRange(location: 0, length: text.length))
        if !hint.isEmpty {
            text.addAttributes(
                [.font: NSFont.systemFont(ofSize: 11),
                 .foregroundColor: NSColor.secondaryLabelColor],
                range: NSRange(location: (message as NSString).length + 1, length: (hint as NSString).length))
        }
        status.attributedStringValue = text
    }

    // MARK: - Menu bar

    private static func icon(_ symbol: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Copy Save")
        image?.isTemplate = true
        return image
    }
    private static let idleIcon = icon("photo.on.rectangle")
    private static let savedIcon = icon("checkmark.circle.fill")
    private static let failedIcon = icon("exclamationmark.triangle.fill")

    /// Left-click saves straight away; right- or control-click opens the menu.
    private func buildStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = Self.idleIcon
        button.toolTip = "Copy Save — click to save the clipboard image"
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        guard wantsMenu else { return paste(nil) }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(withTitle: "Save Clipboard Image", action: #selector(paste(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Show Window", action: #selector(showWindow), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Copy Save", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.items.forEach { $0.target = $0.action == #selector(NSApplication.terminate(_:)) ? NSApp : self }
        return menu
    }()

    /// Shows the outcome of a save when the window is closed or hidden.
    private func flashStatusItem(_ image: NSImage?) {
        statusItem.button?.image = image
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.statusItem.button?.image = Self.idleIcon
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
