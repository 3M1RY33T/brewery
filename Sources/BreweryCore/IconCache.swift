import Foundation
import ImageIO

/// Rejects anything that is not a decodable image of usable size.
public enum IconValidator {
    /// Below this an icon is a blurry smudge next to the app name, and is
    /// worse than the glyph it would replace.
    public static let minimumPixelSize = 16

    public static func isUsableIcon(_ data: Data) -> Bool {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return false
        }
        return width >= minimumPixelSize && height >= minimumPixelSize
    }
}

/// Downloaded icons, kept next to the catalog cache so both clear together.
public struct IconDiskCache: Sendable {
    public enum Entry: Equatable {
        case hit(Data)
        /// A previous resolution found nothing and has not expired yet.
        case miss
        /// Never resolved, or the cached result went stale.
        case absent
    }

    public let directory: URL
    public let hitLifetime: TimeInterval
    public let missLifetime: TimeInterval

    public init(
        directory: URL = IconDiskCache.defaultDirectory(),
        hitLifetime: TimeInterval = 60 * 60 * 24 * 30,
        missLifetime: TimeInterval = 60 * 60 * 24 * 7
    ) {
        self.directory = directory
        self.hitLifetime = hitLifetime
        self.missLifetime = missLifetime
    }

    /// Bumped when the resolution rules change in a way that makes cached
    /// icons wrong, so users are not stuck with them for the hit lifetime.
    /// v2: forge favicons no longer stand in for the apps hosted there.
    public static let formatVersion = 2

    public static func defaultDirectory() -> URL {
        brewerySupportDirectory().appendingPathComponent("IconCache-v\(formatVersion)", isDirectory: true)
    }

    /// Cache directories written by earlier formats, safe to delete.
    public static func legacyDirectories() -> [URL] {
        let base = brewerySupportDirectory()
        return [base.appendingPathComponent("IconCache", isDirectory: true)]
            + (1..<formatVersion).map { base.appendingPathComponent("IconCache-v\($0)", isDirectory: true) }
    }

    private static func brewerySupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("Brewery", isDirectory: true)
    }

    public func load(_ cacheKey: String) -> Entry {
        let url = fileURL(for: cacheKey)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attributes[.modificationDate] as? Date else {
            return .absent
        }

        let age = Date().timeIntervalSince(modified)
        let size = (attributes[.size] as? Int) ?? 0

        // A zero byte file is the marker for "resolved to nothing".
        guard size > 0 else {
            return age < missLifetime ? .miss : .absent
        }
        guard age < hitLifetime, let data = try? Data(contentsOf: url) else {
            return .absent
        }
        return .hit(data)
    }

    public func store(_ data: Data, for cacheKey: String) {
        write(data, for: cacheKey)
    }

    public func storeMiss(for cacheKey: String) {
        write(Data(), for: cacheKey)
    }

    private func write(_ data: Data, for cacheKey: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL(for: cacheKey), options: [.atomic])
    }

    public func fileURL(for cacheKey: String) -> URL {
        directory.appendingPathComponent(IconDiskCache.sanitize(cacheKey), isDirectory: false)
    }

    /// Package ids carry a `cask:` prefix and tokens allow `@`, `+` and `.`,
    /// none of which belong in a file name. Replacing them all with `-` would
    /// give `foo@1` and `foo-1` the same file, so the original key's hash is
    /// appended to keep distinct casks on distinct files.
    public static func sanitize(_ cacheKey: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let mapped = cacheKey.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        return "\(String(mapped.prefix(96)))-\(stableHash(cacheKey))"
    }

    /// FNV-1a. `hashValue` is seeded per process and cannot name a file that
    /// has to be found again on the next launch.
    private static func stableHash(_ value: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in Array(value.utf8) {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return String(hash, radix: 16)
    }
}
