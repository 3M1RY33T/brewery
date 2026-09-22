import Foundation

/// Where a package's icon can be read from, in the order worth trying.
public enum PackageIconSource: Equatable {
    /// An `.app` bundle already on disk. macOS renders its icon at any size.
    case appBundle(URL)
    /// An image to download. Only reached when nothing local matches.
    case remote(URL)
}

/// Turns a cask's declared app bundle and homepage into icon candidates.
///
/// Nothing here touches the filesystem beyond an existence check, and nothing
/// performs I/O, so the ordering is testable on its own.
public enum PackageIconResolver {
    /// Where cask `app` artifacts land. Homebrew targets `/Applications` for
    /// all but a handful of casks, which use the same path under the home
    /// directory.
    public static func defaultApplicationDirectories() -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]
    }

    /// Where Homebrew keeps its per-cask install directories.
    public static func defaultCaskroomDirectories() -> [URL] {
        [
            URL(fileURLWithPath: "/opt/homebrew/Caskroom", isDirectory: true),
            URL(fileURLWithPath: "/usr/local/Caskroom", isDirectory: true)
        ]
    }

    /// The Caskroom belonging to a detected `brew` executable at
    /// `<prefix>/bin/brew`, for prefixes that are not one of the standard two.
    public static func caskroomDirectory(forBrewAt brewPath: URL) -> URL {
        brewPath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Caskroom", isDirectory: true)
    }

    /// The app an installed cask actually put on disk.
    ///
    /// Homebrew symlinks the installed bundle into
    /// `Caskroom/<token>/<version>/`, under the name it had at install time.
    /// That beats the name the cask declares today, which drifts when the
    /// upstream app is renamed across major versions.
    public static func installedAppBundleURL(
        token: String,
        in caskroomDirectories: [URL]? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        guard !token.isEmpty, !token.contains("/"), !token.hasPrefix(".") else { return nil }

        for caskroom in caskroomDirectories ?? defaultCaskroomDirectories() {
            let caskDirectory = caskroom.appendingPathComponent(token, isDirectory: true)
            guard let versions = try? fileManager.contentsOfDirectory(
                at: caskDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            // Newest version directory first, when a cask has more than one.
            for version in versions.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
                guard let entries = try? fileManager.contentsOfDirectory(
                    at: version,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ) else { continue }

                guard let app = entries.first(where: { $0.pathExtension == "app" }) else { continue }

                // The symlink outlives an app dragged to the trash by hand.
                let resolved = app.resolvingSymlinksInPath()
                if fileManager.fileExists(atPath: resolved.path) {
                    return resolved
                }
            }
        }
        return nil
    }

    /// The installed bundle matching `bundleName`, if the user has it.
    ///
    /// This is checked for every cask, not just ones brew reports as
    /// installed: an app placed in Applications by hand still has the icon,
    /// and finding it saves a network round trip.
    public static func localAppBundleURL(
        forBundleNamed bundleName: String,
        in directories: [URL]? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        guard !bundleName.isEmpty, !bundleName.contains("/") else { return nil }

        for directory in directories ?? defaultApplicationDirectories() {
            let candidate = directory.appendingPathComponent(bundleName, isDirectory: true)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    /// Hosts whose favicon says nothing about the app hosted there. A cask
    /// on GitHub is not a GitHub product, and showing the Octocat for a
    /// thousand casks misrepresents every one of them.
    public static let sharedHosts: Set<String> = [
        "github.com", "gitlab.com", "bitbucket.org", "codeberg.org", "sourceforge.net",
        "gitee.com", "framagit.org", "sr.ht", "git.sr.ht", "notabug.org",
        "fonts.google.com", "pypi.org", "npmjs.com", "crates.io", "rubygems.org",
        "apps.apple.com", "chromewebstore.google.com", "addons.mozilla.org"
    ]

    /// GitHub paths that are site features rather than a user or organisation.
    private static let gitHubReservedOwners: Set<String> = [
        "about", "apps", "collections", "enterprise", "explore", "features", "login",
        "marketplace", "orgs", "pricing", "security", "settings", "sponsors", "topics", "trending"
    ]

    /// Homebrew's convention for font casks. Fonts have no icon of their own,
    /// and whatever their homepage serves is either a forge or a foundry.
    public static func isFont(token: String) -> Bool {
        token.hasPrefix("font-")
    }

    /// Icon URLs derived from a homepage, best quality first.
    ///
    /// The vendor's own site is tried first. DuckDuckGo's icon service is the
    /// last resort, and reaching it discloses the homepage's host. Shared
    /// hosts are skipped entirely, except GitHub, where the owner's avatar
    /// is the publisher's logo and is what the App Store would show.
    public static func remoteIconCandidates(homepage: URL?) -> [URL] {
        guard let homepage,
              let scheme = homepage.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let rawHost = homepage.host,
              !rawHost.isEmpty else { return [] }

        let host = rawHost.lowercased()
        let bareHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host

        if bareHost == "github.com" {
            return gitHubOwnerAvatar(for: homepage).map { [$0] } ?? []
        }
        guard !sharedHosts.contains(bareHost) else { return [] }

        return [
            URL(string: "https://\(host)/apple-touch-icon.png"),
            URL(string: "https://\(host)/favicon.ico"),
            URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico")
        ].compactMap { $0 }
    }

    /// `https://github.com/<owner>.png` serves the user or organisation
    /// avatar; `size` picks the rendition.
    static func gitHubOwnerAvatar(for homepage: URL) -> URL? {
        let components = homepage.path.split(separator: "/").map(String.init)
        guard let owner = components.first,
              !owner.isEmpty,
              !gitHubReservedOwners.contains(owner.lowercased()) else { return nil }
        return URL(string: "https://github.com/\(owner).png?size=128")
    }

    /// The full ordered candidate list for a package.
    ///
    /// Formulae are command line tools with no bundle, so they keep their
    /// glyph rather than borrowing a website's favicon.
    public static func sources(
        kind: PackageKind,
        token: String,
        appBundleName: String?,
        homepage: URL?,
        applicationDirectories: [URL]? = nil,
        caskroomDirectories: [URL]? = nil,
        fileManager: FileManager = .default
    ) -> [PackageIconSource] {
        guard kind == .cask, !isFont(token: token) else { return [] }

        // What the cask actually installed, then what it says it installs.
        // Either way the bundle is local and carries the real icon.
        if let installed = installedAppBundleURL(
            token: token,
            in: caskroomDirectories,
            fileManager: fileManager
        ) {
            return [.appBundle(installed)]
        }

        if let appBundleName,
           let bundleURL = localAppBundleURL(
               forBundleNamed: appBundleName,
               in: applicationDirectories,
               fileManager: fileManager
           ) {
            return [.appBundle(bundleURL)]
        }

        return remoteIconCandidates(homepage: homepage).map(PackageIconSource.remote)
    }
}
