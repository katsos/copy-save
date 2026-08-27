import AppKit
import UniformTypeIdentifiers

final class DropView: NSView {
    var onImage: ((NSImage, String?) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL, .tiff, .png])
    }
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        readImage(from: sender.draggingPasteboard)
    }

    @discardableResult
    func readImage(from pb: NSPasteboard) -> Bool {
        // Prefer file URLs so the original name/format is kept.
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            var handled = false
            for url in urls {
                guard let type = UTType(filenameExtension: url.pathExtension),
                      type.conforms(to: .image),
                      let image = NSImage(contentsOf: url) else { continue }
                onImage?(image, url.lastPathComponent)
                handled = true
            }
            if handled { return true }
        }
        if let image = NSImage(pasteboard: pb) {
            onImage?(image, nil)
            return true
        }
        return false
    }
}

final class StatusLabel: NSTextField {
    convenience init(text: String) {
        self.init(labelWithString: text)
        alignment = .center
        lineBreakMode = .byTruncatingMiddle
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var dropView: DropView!
    private let status = StatusLabel(text: "Press ⌘V to paste an image,\nor drag one here.")
    private let detail = StatusLabel(text: "")
    private var savedCount = 0

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
        dropView.onImage = { [weak self] image, name in self?.save(image, suggestedName: name) }

        status.font = .systemFont(ofSize: 15, weight: .medium)
        status.maximumNumberOfLines = 3
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        detail.maximumNumberOfLines = 2

        let stack = NSStackView(views: [status, detail])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        dropView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: dropView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: dropView.centerYAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualTo: dropView.widthAnchor, constant: -40),
        ])

        window.contentView = dropView
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(dropView)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc func paste(_ sender: Any?) {
        if !dropView.readImage(from: .general) {
            report("No image on the clipboard.", detail: "Copy an image, then press ⌘V.")
            readyForNextPaste()
        }
    }

    /// Keeps the drop view as first responder so every following ⌘V lands here too.
    private func readyForNextPaste() {
        if window.firstResponder !== dropView {
            window.makeFirstResponder(dropView)
        }
    }

    private func save(_ image: NSImage, suggestedName: String?) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            report("Could not encode that image.", detail: nil)
            return
        }

        let base = suggestedName.map { ($0 as NSString).deletingPathExtension } ?? "Clipboard"
        let url = uniqueURL(in: desktop, base: base, ext: "png")

        do {
            try png.write(to: url)
            savedCount += 1
            report("Saved \(url.lastPathComponent)",
                   detail: "\(savedCount) saved this session — copy another image and press ⌘V again.")
        } catch {
            report("Save failed.", detail: error.localizedDescription)
        }
        readyForNextPaste()
    }

    private func uniqueURL(in dir: URL, base: String, ext: String) -> URL {
        let stamp = Self.formatter.string(from: Date())
        var candidate = dir.appendingPathComponent("\(base) \(stamp).\(ext)")
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base) \(stamp)-\(n).\(ext)")
            n += 1
        }
        return candidate
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return f
    }()

    private func report(_ message: String, detail text: String?) {
        status.stringValue = message
        detail.stringValue = text ?? ""
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
