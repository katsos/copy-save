import AppKit
import Carbon.HIToolbox
import ImageIO
import UniformTypeIdentifiers

// MARK: - Output format

/// Both are encoded by macOS itself, so the app needs nothing installed.
enum Format: String, CaseIterable {
    case png, heic

    var label: String {
        switch self {
        case .png: return "PNG"
        case .heic: return "HEIC"
        }
    }
}

// MARK: - Preferences

enum Prefs {
    private static let defaults = UserDefaults.standard

    static var destination: URL {
        get {
            defaults.string(forKey: "destination").map { URL(fileURLWithPath: $0) }
                ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        }
        set { defaults.set(newValue.path, forKey: "destination") }
    }

    static var format: Format {
        get { Format(rawValue: defaults.string(forKey: "format") ?? "") ?? .png }
        set { defaults.set(newValue.rawValue, forKey: "format") }
    }

    /// nil when no shortcut is set — the menu bar click is always enough.
    static var shortcut: (keyCode: UInt32, modifiers: NSEvent.ModifierFlags, label: String)? {
        get {
            guard let label = defaults.string(forKey: "shortcutLabel") else { return nil }
            return (UInt32(defaults.integer(forKey: "shortcutKeyCode")),
                    NSEvent.ModifierFlags(rawValue: UInt(defaults.integer(forKey: "shortcutModifiers"))),
                    label)
        }
        set {
            defaults.set(newValue?.label, forKey: "shortcutLabel")
            defaults.set(Int(newValue?.keyCode ?? 0), forKey: "shortcutKeyCode")
            defaults.set(Int(newValue?.modifiers.rawValue ?? 0), forKey: "shortcutModifiers")
        }
    }
}

// MARK: - Global shortcut

/// Carbon's RegisterEventHotKey is the only global hotkey API that needs no
/// Accessibility permission.
final class HotKey {
    static let shared = HotKey()
    var action: (() -> Void)?

    private var ref: EventHotKeyRef?
    private var handlerInstalled = false
    private init() {}

    func apply() {
        if let ref { UnregisterEventHotKey(ref); self.ref = nil }
        guard let shortcut = Prefs.shortcut else { return }

        if !handlerInstalled {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                HotKey.shared.action?()
                return noErr
            }, 1, &spec, nil, nil)
            handlerInstalled = true
        }

        var carbon: UInt32 = 0
        if shortcut.modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if shortcut.modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if shortcut.modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if shortcut.modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }

        RegisterEventHotKey(shortcut.keyCode, carbon,
                            EventHotKeyID(signature: OSType(0x43505356), id: 1),
                            GetApplicationEventTarget(), 0, &ref)
    }
}

/// A button that turns the next keypress into a shortcut.
final class ShortcutRecorder: NSButton {
    var onCapture: (() -> Void)?
    private var monitor: Any?

    convenience init() {
        self.init(title: "", target: nil, action: nil)
        bezelStyle = .rounded
        target = self
        action = #selector(startRecording)
        refresh()
    }

    func refresh() {
        title = Prefs.shortcut?.label ?? "Click to record"
    }

    @objc private func startRecording() {
        guard monitor == nil else { return stopRecording() }
        title = "Type a shortcut…"
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.capture(event)
            return nil
        }
    }

    private func capture(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if event.keyCode == UInt16(kVK_Escape) && modifiers.isEmpty { return stopRecording() }
        // A shortcut with no command/option/control would swallow plain typing.
        guard !modifiers.intersection([.command, .option, .control]).isEmpty else { return }

        var label = ""
        if modifiers.contains(.control) { label += "⌃" }
        if modifiers.contains(.option) { label += "⌥" }
        if modifiers.contains(.shift) { label += "⇧" }
        if modifiers.contains(.command) { label += "⌘" }
        label += (event.charactersIgnoringModifiers ?? "").uppercased()

        Prefs.shortcut = (UInt32(event.keyCode), modifiers, label)
        stopRecording()
        onCapture?()
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        refresh()
    }
}

// MARK: - Settings

final class SettingsWindow: NSWindowController {
    private let recorder = ShortcutRecorder()
    private let destination = NSTextField(labelWithString: "")
    private let formats = NSPopUpButton()

    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 170),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = "Copy Save Settings"
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.contentView = buildContent()
        window.center()
    }

    private func buildContent() -> NSView {
        recorder.onCapture = { HotKey.shared.apply() }

        let clear = NSButton(title: "Clear", target: self, action: #selector(clearShortcut))
        let choose = NSButton(title: "Choose…", target: self, action: #selector(chooseDestination))
        destination.lineBreakMode = .byTruncatingHead

        for format in Format.allCases {
            let item = NSMenuItem(title: format.label, action: nil, keyEquivalent: "")
            item.representedObject = format
            formats.menu?.addItem(item)
        }
        formats.target = self
        formats.action = #selector(chooseFormat)

        let note = NSTextField(labelWithString: "HEIC files are much smaller; PNG opens anywhere.")
        note.font = .systemFont(ofSize: 11)
        note.textColor = .secondaryLabelColor

        let grid = NSGridView(views: [
            [label("Shortcut:"), recorder, clear],
            [label("Save to:"), destination, choose],
            [label("Format:"), formats, NSGridCell.emptyContentView],
            [NSGridCell.emptyContentView, note, NSGridCell.emptyContentView],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowSpacing = 12
        grid.columnSpacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            destination.widthAnchor.constraint(equalToConstant: 240),
        ])
        refresh()
        return content
    }

    private func label(_ text: String) -> NSTextField { NSTextField(labelWithString: text) }

    func refresh() {
        recorder.refresh()
        destination.stringValue = Prefs.destination.path
        formats.selectItem(withTitle: Prefs.format.label)
    }

    @objc private func clearShortcut() {
        Prefs.shortcut = nil
        HotKey.shared.apply()
        recorder.refresh()
    }

    @objc private func chooseDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = Prefs.destination
        panel.prompt = "Save Here"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Prefs.destination = url
        refresh()
    }

    @objc private func chooseFormat() {
        guard let format = formats.selectedItem?.representedObject as? Format else { return }
        Prefs.format = format
        refresh()
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private lazy var settings = SettingsWindow()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let button = statusItem.button else { return }
        button.image = Self.idleIcon
        button.toolTip = "Copy Save — click to save the clipboard image"
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        HotKey.shared.action = { [weak self] in self?.save() }
        HotKey.shared.apply()
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
        menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Copy Save", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.items.forEach { $0.target = $0.action == #selector(NSApplication.terminate(_:)) ? NSApp : self }
        return menu
    }()

    @objc private func showSettings() {
        settings.refresh()
        NSApp.activate(ignoringOtherApps: true)
        settings.showWindow(nil)
        settings.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func save() {
        guard let image = NSImage(pasteboard: .general) else {
            return report("No image on the clipboard.", "Copy an image, then click the Copy Save icon.")
        }

        let format = Prefs.format
        let url = Prefs.destination
            .appendingPathComponent("Clipboard \(Self.formatter.string(from: Date())).\(format.rawValue)")
        do {
            try Self.encode(image, as: format).write(to: url)
            flash(Self.savedIcon)
        } catch {
            report("Could not save the image.", error.localizedDescription)
        }
    }

    private enum EncodeError: LocalizedError {
        case unreadable, encoder(String)
        var errorDescription: String? {
            switch self {
            case .unreadable: return "That image could not be read."
            case .encoder(let detail): return detail
            }
        }
    }

    private static func encode(_ image: NSImage, as format: Format) throws -> Data {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            throw EncodeError.unreadable
        }

        switch format {
        case .png:
            guard let png = rep.representation(using: .png, properties: [:]) else {
                throw EncodeError.unreadable
            }
            return png
        case .heic:
            guard let cgImage = rep.cgImage else { throw EncodeError.unreadable }
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                    data, UTType.heic.identifier as CFString, 1, nil) else {
                throw EncodeError.encoder("This Mac cannot encode HEIC.")
            }
            CGImageDestinationAddImage(destination, cgImage,
                                       [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                throw EncodeError.encoder("HEIC encoding failed.")
            }
            return data as Data
        }
    }

    /// A success is a 1.5s checkmark in the menu bar; a failure needs words, and
    /// with no main window there is nowhere else to put them.
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
