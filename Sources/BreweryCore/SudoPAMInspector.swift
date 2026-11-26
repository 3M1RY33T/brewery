import Foundation

/// How this Mac's `sudo` will authenticate an administrator step, read from
/// the PAM configuration that `sudo` consults. Brewery's password sheet only
/// appears once sudo reaches its password step; a hardware token (Touch ID or
/// a smartcard) that sits `sufficient` before that step answers sudo first,
/// so the sheet never shows.
public struct SudoPAMReport: Equatable {
    /// Module names (e.g. `pam_tid.so`, `pam_smartcard.so`) found in an
    /// `auth … sufficient` position.
    public let preemptingModules: [String]
    /// The config files those modules were found in.
    public let sources: [String]

    public init(preemptingModules: [String], sources: [String]) {
        self.preemptingModules = preemptingModules
        self.sources = sources
    }

    public var usesTouchID: Bool {
        preemptingModules.contains { $0.contains("pam_tid") }
    }

    public var usesSmartcard: Bool {
        preemptingModules.contains { $0.contains("pam_smartcard") }
    }

    /// True when a non-password module will answer sudo before the password
    /// step, so Brewery's password sheet may never be reached.
    public var canPreemptPassword: Bool { !preemptingModules.isEmpty }

    /// One-line explanation shown in the command log and diagnostics.
    public var explanation: String {
        if usesTouchID {
            return "Touch ID answers sudo before its password step, so a command that needs administrator rights may ask for your fingerprint instead of Brewery's password sheet."
        }
        if usesSmartcard {
            return "A smartcard answers sudo before its password step, so a command that needs administrator rights may ask for the card instead of Brewery's password sheet."
        }
        return "Sudo uses password authentication."
    }

    /// The explanation, or nil when there is nothing to warn about.
    public var preemptionNotice: String? {
        canPreemptPassword ? explanation : nil
    }

    /// Short headline for the diagnostics block.
    public var headline: String {
        if usesTouchID { return "Touch ID answers sudo first" }
        if usesSmartcard { return "Smartcard answers sudo first" }
        return "Password authentication"
    }
}

/// Reads the PAM files `sudo` consults and reports any `sufficient` auth
/// module that can satisfy sudo without a password.
public struct SudoPAMInspector {
    public static let standardPaths = ["/etc/pam.d/sudo", "/etc/pam.d/sudo_local"]

    private let paths: [String]
    private let read: (String) throws -> String

    public init(
        paths: [String] = SudoPAMInspector.standardPaths,
        read: @escaping (String) throws -> String = { path in
            try String(contentsOfFile: path, encoding: .utf8)
        }
    ) {
        self.paths = paths
        self.read = read
    }

    public func inspect() -> SudoPAMReport {
        var modules: [String] = []
        var sources: [String] = []
        for path in paths {
            guard let contents = try? read(path) else { continue }
            let found = Self.preemptingModules(in: contents)
            if !found.isEmpty {
                modules.append(contentsOf: found)
                sources.append(path)
            }
        }
        return SudoPAMReport(preemptingModules: modules, sources: sources)
    }

    /// The modules on `auth … sufficient` lines, which run before the password
    /// module and can satisfy sudo on their own.
    static func preemptingModules(in contents: String) -> [String] {
        var result: [String] = []
        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.hasPrefix("#") else { continue }
            let fields = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
                .map(String.init)
                .filter { !$0.isEmpty }
            guard fields.first == "auth", fields.contains("sufficient") else { continue }
            for field in fields {
                let name = (field as NSString).lastPathComponent
                guard name.contains(".so"),
                      name.contains("pam_tid") || name.contains("pam_smartcard")
                else { continue }
                result.append(name)
            }
        }
        return result
    }
}
