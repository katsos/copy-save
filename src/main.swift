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
    private let status = NSTextField(labelWithString: "Press ⌘V to paste an image,\nor drag one here.")

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

        status.alignment = .center
        status.font = .systemFont(ofSize: 15, weight: .medium)
        status.lineBreakMode = .byWordWrapping
        status.maximumNumberOfLines = 4
        status.translatesAutoresizingMaskIntoConstraints = false

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
            report("No image on the clipboard.\nCopy an image, then press ⌘V.")
        }
    }

    private func save(_ image: NSImage) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            report("Could not encode that image.")
            return
        }

        let url = desktop.appendingPathComponent("Clipboard \(Self.formatter.string(from: Date())).png")
        do {
            try png.write(to: url)
            report("Saved \(url.lastPathComponent)\nCopy another image and press ⌘V again.")
        } catch {
            report("Save failed.\n\(error.localizedDescription)")
        }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss.SSS"
        return f
    }()

    private func report(_ message: String) {
        status.stringValue = message
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
