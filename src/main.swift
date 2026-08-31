import AppKit

final class DropView: NSView {
    var onImage: ((NSImage) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL, .tiff, .png])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        readImage(from: sender.draggingPasteboard)
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

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

        status.lineBreakMode = .byWordWrapping
        status.maximumNumberOfLines = 4
        status.translatesAutoresizingMaskIntoConstraints = false
        report("Press ⌘V to paste an image", hint: "…or drag one onto this window.")

        dropView.addSubview(status)
        NSLayoutConstraint.activate([
            status.centerXAnchor.constraint(equalTo: dropView.centerXAnchor),
            status.centerYAnchor.constraint(equalTo: dropView.centerYAnchor),
            status.widthAnchor.constraint(lessThanOrEqualTo: dropView.widthAnchor, constant: -40),
        ])

        window.contentView = dropView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc func paste(_ sender: Any?) {
        if !dropView.readImage(from: .general) {
            report("No image on the clipboard.", hint: "Copy an image, then press ⌘V.")
        }
    }

    private func save(_ image: NSImage) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            report("Could not encode that image.", hint: "")
            return
        }

        let url = desktop.appendingPathComponent("Clipboard \(Self.formatter.string(from: Date())).png")
        do {
            try png.write(to: url)
            report("Saved \(url.lastPathComponent)", hint: "Copy another image and press ⌘V again.")
        } catch {
            report("Save failed.", hint: error.localizedDescription)
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

    private func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Copy Save", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Copy Save", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Copy Save", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Paste", action: #selector(AppDelegate.paste(_:)), keyEquivalent: "v")
        editItem.submenu = editMenu
        main.addItem(editItem)

        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
