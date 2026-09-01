import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Both formats are encoded by macOS itself, so the app needs nothing installed.
enum Format: String, CaseIterable {
    case png, heic

    var label: String {
        switch self {
        case .png: return "PNG"
        case .heic: return "HEIC"
        }
    }
}

enum EncodeError: LocalizedError {
    case unreadable
    case encoder(String)

    var errorDescription: String? {
        switch self {
        case .unreadable: return "That image could not be read."
        case .encoder(let detail): return detail
        }
    }
}

/// Encoding and file naming — the parts of Copy Save that can be tested without
/// a menu bar. See tests/main.swift.
enum Encoder {
    static func encode(_ image: NSImage, as format: Format) throws -> Data {
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

    /// Timestamped to the millisecond, so two saves can never collide.
    static func filename(for date: Date, format: Format) -> String {
        "Clipboard \(formatter.string(from: date)).\(format.rawValue)"
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss.SSS"
        return f
    }()
}
