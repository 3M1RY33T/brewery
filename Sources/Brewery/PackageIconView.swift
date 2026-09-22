import AppKit
import BreweryCore
import ImageIO
import SwiftUI

/// The icon for one package, falling back to the kind glyph.
///
/// A cask that installs an app it can find in Applications renders that app's
/// real icon straight off disk. Everything else falls back to the homepage
/// icon, then to the glyph Brewery has always drawn.
struct PackageIconView: View {
    let kind: PackageKind
    let cacheKey: String
    let token: String
    let appBundleName: String?
    let homepage: URL?
    var size: CGFloat = 46
    var cornerRadius: CGFloat = 8
    /// Called once a real icon is available, for views that derive
    /// something from it, such as a banner colour.
    var onLoad: ((NSImage) -> Void)? = nil

    @State private var icon: NSImage?

    var body: some View {
        ZStack {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(glyphColor.opacity(0.16))
                Image(systemName: glyph)
                    .font(.system(size: size * 0.42))
                    .foregroundColor(glyphColor)
            }
        }
        .frame(width: size, height: size)
        .task(id: cacheKey) {
            icon = await PackageIconLoader.shared.icon(
                kind: kind,
                cacheKey: cacheKey,
                token: token,
                appBundleName: appBundleName,
                homepage: homepage
            )
            if let icon { onLoad?(icon) }
        }
    }

    private var isFont: Bool { kind == .cask && PackageIconResolver.isFont(token: token) }

    /// Fonts get their own glyph: a window is not what they install.
    private var glyph: String {
        if isFont { return "textformat" }
        return kind == .cask ? "macwindow" : "terminal"
    }

    private var glyphColor: Color {
        if isFont { return .purple }
        return kind == .cask ? .blue : .green
    }
}

extension PackageIconView {
    init(package: BrewPackage, size: CGFloat = 46, cornerRadius: CGFloat = 8, onLoad: ((NSImage) -> Void)? = nil) {
        self.init(
            kind: package.kind,
            cacheKey: package.id,
            token: package.name,
            appBundleName: package.appBundleName,
            homepage: package.homepage,
            size: size,
            cornerRadius: cornerRadius,
            onLoad: onLoad
        )
    }

    init(package: CatalogPackage, size: CGFloat = 46, cornerRadius: CGFloat = 8, onLoad: ((NSImage) -> Void)? = nil) {
        self.init(
            kind: package.kind,
            cacheKey: package.id,
            token: package.name,
            appBundleName: package.appBundleName,
            homepage: package.homepage,
            size: size,
            cornerRadius: cornerRadius,
            onLoad: onLoad
        )
    }
}

/// Resolves and caches package icons.
///
/// Browse can scroll past thousands of casks, so a resolved icon is cached in
/// memory for the session and on disk across launches, and a package that
/// yields nothing is remembered as a miss so its homepage is not retried on
/// every scroll.
@MainActor
final class PackageIconLoader {
    static let shared = PackageIconLoader()

    /// What resolution produced, before it becomes an image. Kept free of
    /// `NSImage` so it can cross a task boundary on macOS 12, where `NSImage`
    /// is not `Sendable`.
    private enum ResolvedIcon: Sendable {
        case appBundle(path: String)
        case downloaded(Data)
    }

    private let memory = NSCache<NSString, NSImage>()
    private var inFlight: [String: Task<ResolvedIcon?, Never>] = [:]
    private nonisolated let diskCache: IconDiskCache
    private nonisolated let session: URLSession
    /// Set once Homebrew has been located, so a prefix other than the two
    /// standard ones still resolves installed apps.
    private var caskroomDirectories: [URL]?

    init(diskCache: IconDiskCache = IconDiskCache(), session: URLSession? = nil) {
        self.diskCache = diskCache

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 15
        configuration.httpMaximumConnectionsPerHost = 2
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        self.session = session ?? URLSession(configuration: configuration)

        memory.countLimit = 600

        // Icons cached under an earlier format may be wrong; drop them so
        // they are re-resolved under the current rules.
        Task.detached(priority: .utility) {
            for directory in IconDiskCache.legacyDirectories() {
                try? FileManager.default.removeItem(at: directory)
            }
        }
    }

    /// Points icon lookup at the Caskroom belonging to the detected `brew`.
    func configure(brewPath: URL?) {
        guard let brewPath else { return }
        let caskroom = PackageIconResolver.caskroomDirectory(forBrewAt: brewPath)
        guard !PackageIconResolver.defaultCaskroomDirectories().contains(caskroom) else { return }
        caskroomDirectories = [caskroom] + PackageIconResolver.defaultCaskroomDirectories()
    }

    func icon(
        kind: PackageKind,
        cacheKey: String,
        token: String,
        appBundleName: String?,
        homepage: URL?
    ) async -> NSImage? {
        if let cached = memory.object(forKey: cacheKey as NSString) {
            return cached
        }
        if let existing = inFlight[cacheKey] {
            return Self.image(from: await existing.value)
        }

        let task = Task { [diskCache, session, caskroomDirectories] () -> ResolvedIcon? in
            await PackageIconLoader.resolve(
                kind: kind,
                cacheKey: cacheKey,
                token: token,
                appBundleName: appBundleName,
                homepage: homepage,
                caskroomDirectories: caskroomDirectories,
                diskCache: diskCache,
                session: session
            )
        }
        inFlight[cacheKey] = task
        let resolved = await task.value
        inFlight[cacheKey] = nil

        guard let image = Self.image(from: resolved) else { return nil }
        memory.setObject(image, forKey: cacheKey as NSString)
        return image
    }

    private static func image(from resolved: ResolvedIcon?) -> NSImage? {
        switch resolved {
        case .appBundle(let path):
            let icon = NSWorkspace.shared.icon(forFile: path)
            icon.size = NSSize(width: 128, height: 128)
            return icon
        case .downloaded(let data):
            return NSImage(data: data)
        case nil:
            return nil
        }
    }

    private static func resolve(
        kind: PackageKind,
        cacheKey: String,
        token: String,
        appBundleName: String?,
        homepage: URL?,
        caskroomDirectories: [URL]?,
        diskCache: IconDiskCache,
        session: URLSession
    ) async -> ResolvedIcon? {
        let sources = PackageIconResolver.sources(
            kind: kind,
            token: token,
            appBundleName: appBundleName,
            homepage: homepage,
            caskroomDirectories: caskroomDirectories
        )
        guard !sources.isEmpty else { return nil }

        // An app already in Applications is the best icon available, and needs
        // no network at all.
        if case .appBundle(let bundleURL) = sources.first {
            return .appBundle(path: bundleURL.path)
        }

        let remoteURLs: [URL] = sources.compactMap { source in
            guard case .remote(let url) = source else { return nil }
            return url
        }

        guard let data = await fetchRemoteIconData(
            cacheKey: cacheKey,
            candidates: remoteURLs,
            diskCache: diskCache,
            session: session
        ) else { return nil }
        return .downloaded(data)
    }

    /// Runs off the main actor: disk cache lookup, then each candidate in turn.
    private static func fetchRemoteIconData(
        cacheKey: String,
        candidates: [URL],
        diskCache: IconDiskCache,
        session: URLSession
    ) async -> Data? {
        switch diskCache.load(cacheKey) {
        case .hit(let data):
            return data
        case .miss:
            return nil
        case .absent:
            break
        }

        for url in candidates {
            if Task.isCancelled { return nil }
            guard let data = try? await downloadIcon(from: url, session: session) else { continue }
            diskCache.store(data, for: cacheKey)
            return data
        }

        // Nothing answered. Remember that, so scrolling back does not retry
        // every homepage in the catalog.
        if !Task.isCancelled {
            diskCache.storeMiss(for: cacheKey)
        }
        return nil
    }

    private static func downloadIcon(from url: URL, session: URLSession) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw IconError.unusable
        }
        // Sites commonly answer a missing favicon with a 200 HTML error page.
        guard IconValidator.isUsableIcon(data) else { throw IconError.unusable }
        return data
    }

    private enum IconError: Error {
        case unusable
    }
}


extension NSImage {
    /// The colour that dominates an icon, for tinting a banner behind it.
    ///
    /// Downsamples to a small bitmap, drops transparent, near-white and
    /// near-black pixels, then takes the heaviest hue band rather than the
    /// mean: a multicolour icon such as Google Cloud's is mostly blue, and
    /// averaging its blue, red and yellow would have produced a green it does
    /// not contain. Returns nil for an effectively grayscale icon so the
    /// caller can choose a neutral tint rather than invent one.
    func dominantColor() -> NSColor? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let side = 24
        guard let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }
        let pixels = data.assumingMemoryBound(to: UInt8.self)

        struct Sample { let hue: Double; let saturation: Double; let brightness: Double; let weight: Double }
        var samples: [Sample] = []
        samples.reserveCapacity(side * side)

        for index in 0..<(side * side) {
            let alpha = Double(pixels[index * 4 + 3]) / 255
            guard alpha > 0.5 else { continue }
            // Premultiplied: recover the source colour before judging it.
            let red = Double(pixels[index * 4]) / 255 / alpha
            let green = Double(pixels[index * 4 + 1]) / 255 / alpha
            let blue = Double(pixels[index * 4 + 2]) / 255 / alpha

            let maxChannel = max(red, green, blue)
            let minChannel = min(red, green, blue)
            let delta = maxChannel - minChannel
            let value = maxChannel
            let sat = maxChannel > 0 ? delta / maxChannel : 0
            guard sat > 0.18, value > 0.18, value < 0.97 else { continue }

            var hue: Double
            switch maxChannel {
            case red: hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            case green: hue = (blue - red) / delta + 2
            default: hue = (red - green) / delta + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }

            samples.append(Sample(hue: hue, saturation: sat, brightness: value, weight: sat * alpha))
        }

        // Under ~4% saturated coverage the icon is monochrome for our purposes.
        let total = samples.reduce(0) { $0 + $1.weight }
        guard total > Double(side * side) * 0.04 else { return nil }

        // Heaviest of 24 hue bands, each 15 degrees wide.
        let bands = 24
        var bandWeight = [Double](repeating: 0, count: bands)
        for sample in samples {
            bandWeight[min(Int(sample.hue * Double(bands)), bands - 1)] += sample.weight
        }
        guard let peak = bandWeight.indices.max(by: { bandWeight[$0] < bandWeight[$1] }) else { return nil }

        // Average within the peak band and its neighbours as a vector, so a
        // hue straddling a band edge is not split in two, and red at 0/1 is
        // not averaged with itself into cyan.
        var x = 0.0, y = 0.0, saturation = 0.0, brightness = 0.0, weight = 0.0
        for sample in samples {
            let band = min(Int(sample.hue * Double(bands)), bands - 1)
            let distance = min(abs(band - peak), bands - abs(band - peak))
            guard distance <= 1 else { continue }
            x += cos(sample.hue * 2 * .pi) * sample.weight
            y += sin(sample.hue * 2 * .pi) * sample.weight
            saturation += sample.saturation * sample.weight
            brightness += sample.brightness * sample.weight
            weight += sample.weight
        }
        guard weight > 0 else { return nil }

        var hue = atan2(y, x) / (2 * .pi)
        if hue < 0 { hue += 1 }
        return NSColor(hue: hue, saturation: saturation / weight, brightness: brightness / weight, alpha: 1)
    }
}
