import AppKit

// A tiny assertion harness. XCTest would mean a SwiftPM package; the app is
// built with a bare swiftc call and the tests keep that shape.
var failures = 0

func check(_ name: String, _ condition: @autoclosure () throws -> Bool) {
    do {
        if try condition() {
            print("  ok   \(name)")
        } else {
            print("  FAIL \(name)")
            failures += 1
        }
    } catch {
        print("  FAIL \(name) — threw \(error)")
        failures += 1
    }
}

func image(width: Int = 16, height: Int = 16) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    NSColor.systemPink.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    image.unlockFocus()
    return image
}

print("Encoder.encode")
let png = try? Encoder.encode(image(), as: .png)
check("PNG starts with the PNG signature", png?.prefix(8).elementsEqual([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) == true)
check("PNG round-trips back into an NSImage", NSImage(data: png ?? Data())?.size == NSSize(width: 16, height: 16))

let heic = try? Encoder.encode(image(), as: .heic)
check("HEIC is a non-empty ISO media file", (heic?.count ?? 0) > 0 && heic?.dropFirst(4).prefix(4).elementsEqual(Array("ftyp".utf8)) == true)
check("HEIC round-trips back into an NSImage", NSImage(data: heic ?? Data()) != nil)

check("an empty image cannot be encoded", {
    do {
        _ = try Encoder.encode(NSImage(), as: .png)
        return false
    } catch {
        return true
    }
}())

print("Encoder.filename")
var components = DateComponents()
components.year = 2026; components.month = 8; components.day = 31
components.hour = 12; components.minute = 42; components.second = 21; components.nanosecond = 783_000_000
let date = Calendar.current.date(from: components)!

check("names a PNG with a millisecond stamp",
      Encoder.filename(for: date, format: .png) == "Clipboard 2026-08-31 at 12.42.21.783.png")
check("uses the chosen format's extension",
      Encoder.filename(for: date, format: .heic).hasSuffix(".heic"))
check("two saves a millisecond apart get different names",
      Encoder.filename(for: date, format: .png)
          != Encoder.filename(for: date.addingTimeInterval(0.001), format: .png))

print("Format")
check("every format has a label", Format.allCases.allSatisfy { !$0.label.isEmpty })
check("every format's extension is its raw value", Format.allCases.allSatisfy { !$0.rawValue.isEmpty })

print(failures == 0 ? "\nall tests passed" : "\n\(failures) test(s) failed")
exit(failures == 0 ? 0 : 1)
