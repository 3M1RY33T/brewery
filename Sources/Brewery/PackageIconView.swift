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
                    .fill(kind == .cask ? Color.blue.opacity(0.16) : Color.green.opacity(0.16))
                Image(systemName: kind == .cask ? "macwindow" : "terminal")
                    .font(.system(size: size * 0.42))
                    .foregroundColor(kind == .cask ? .blue : .green)
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
        }
    }
}

extension PackageIconView {
    init(package: BrewPackage, size: CGFloat = 46, cornerRadius: CGFloat = 8) {
        self.init(
            kind: package.kind,
            cacheKey: package.id,
            token: package.name,
            appBundleName: package.appBundleName,
            homepage: package.homepage,
            size: size,
            cornerRadius: cornerRadius
        )
    }

    init(package: CatalogPackage, size: CGFloat = 46, cornerRadius: CGFloat = 8) {
        self.init(
            kind: package.kind,
            cacheKey: package.id,
            token: package.name,
            appBundleName: package.appBundleName,
            homepage: package.homepage,
            size: size,
            cornerRadius: cornerRadius
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
