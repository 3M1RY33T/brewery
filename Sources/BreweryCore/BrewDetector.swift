import Foundation

public struct BrewDetectionReport: Equatable {
    public let checkedPaths: [String]
    public let foundPath: String?
    public let lookupError: String?

    public var isAvailable: Bool { foundPath != nil }

    public static let empty = BrewDetectionReport(checkedPaths: [], foundPath: nil, lookupError: nil)
}

public struct BrewDetector {
    public var fileManager: FileManager
    public var shellLookup: () -> String?

    public init(
        fileManager: FileManager = .default,
        shellLookup: @escaping () -> String? = BrewDetector.defaultShellLookup
    ) {
        self.fileManager = fileManager
        self.shellLookup = shellLookup
    }

    public func detect() -> BrewDetectionReport {
        let candidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        for path in candidates where isExecutable(path) {
            return BrewDetectionReport(checkedPaths: candidates, foundPath: path, lookupError: nil)
        }

        if let shellPath = shellLookup(), isExecutable(shellPath) {
            return BrewDetectionReport(checkedPaths: candidates + ["login shell PATH"], foundPath: shellPath, lookupError: nil)
        }

        return BrewDetectionReport(
            checkedPaths: candidates + ["login shell PATH"],
            foundPath: nil,
            lookupError: "Homebrew was not found in the standard Apple Silicon path, Intel path, or sanitized login shell PATH."
        )
    }

    private func isExecutable(_ path: String) -> Bool {
        fileManager.isExecutableFile(atPath: path)
    }

    public static func defaultShellLookup() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [
            "-lc",
            "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin command -v brew"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
