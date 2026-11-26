import Foundation

/// One thing a line of Homebrew output says about the package being worked on.
public enum BrewProgressEvent: Equatable {
    case fetching(name: String?)
    case downloading(name: String?, detail: String?)
    case installing(name: String?)
    /// A real download percentage, 0...1.
    case progress(Double)
    case finished(name: String?)
    case failed(message: String)
}

/// Turns Homebrew's console output into phase events.
///
/// It holds no UI state: it buffers partial lines, recognises the handful of
/// `==> ` lines that say where a package is, and remembers the last package
/// named so a bare `==> Downloading <url>` still lands on the right entry.
/// The bar is attributed by `DownloadSession`, which knows the queue.
public struct BrewProgressParser {
    private var buffer = ""
    private var lastNamedPackage: String?

    public init() {}

    /// Feeds a chunk of output and returns the events its complete lines
    /// produced. A partial line stays buffered until its ending arrives.
    public mutating func consume(_ text: String) -> [BrewProgressEvent] {
        guard !text.isEmpty else { return [] }
        buffer += text

        var collected: [BrewProgressEvent] = []
        var lineStart = buffer.startIndex
        var index = buffer.startIndex

        while index < buffer.endIndex {
            let character = buffer[index]
            guard character == "\n" || character == "\r" else {
                index = buffer.index(after: index)
                continue
            }

            let line = String(buffer[lineStart..<index])
            collected.append(contentsOf: events(in: line))

            var next = buffer.index(after: index)
            // A carriage return is how curl redraws its progress bar; a
            // Windows line ending is one break, not two.
            if character == "\r", next < buffer.endIndex, buffer[next] == "\n" {
                next = buffer.index(after: next)
            }
            index = next
            lineStart = index
        }

        buffer = String(buffer[lineStart...])
        return collected
    }

    /// Whatever is left when the command ends: a last line with no ending.
    public mutating func flush() -> [BrewProgressEvent] {
        let line = buffer
        buffer = ""
        return events(in: line)
    }

    // MARK: - Line recognition

    private mutating func events(in line: String) -> [BrewProgressEvent] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        // A bottle summary, e.g. "🍺  /opt/homebrew/Cellar/wget/1.25.0: 20 files".
        if trimmed.hasPrefix("🍺") {
            return successEvents(in: trimmed)
        }

        if trimmed.hasPrefix("Error: ") || trimmed.hasPrefix("==> Error: ") {
            let message = trimmed
                .replacingOccurrences(of: "==> ", with: "")
                .replacingOccurrences(of: "Error: ", with: "")
            return [.failed(message: message)]
        }

        var events: [BrewProgressEvent] = []

        if let rest = value(after: "==> ", in: trimmed) {
            events.append(contentsOf: phaseEvents(in: rest))
        }

        if let fraction = Self.progressFraction(in: trimmed) {
            events.append(.progress(fraction))
        }
        return events
    }

    private mutating func phaseEvents(in rest: String) -> [BrewProgressEvent] {
        if let dependencies = value(after: "Fetching dependencies for ", in: rest) {
            let name = packageName(from: dependencies)
            if isPackageName(name) { lastNamedPackage = name }
            return [.fetching(name: lastNamedPackage ?? name)]
        }

        if let fetched = value(after: "Fetching ", in: rest) {
            let name = packageName(from: fetched)
            guard isPackageName(name) else { return [] }
            lastNamedPackage = name
            return [.fetching(name: name)]
        }

        if let download = value(after: "Downloading ", in: rest) {
            return [.downloading(name: lastNamedPackage, detail: downloadFileName(from: download))]
        }

        if let cask = value(after: "Installing Cask ", in: rest) {
            let name = packageName(from: cask)
            guard isPackageName(name) else { return [.installing(name: lastNamedPackage)] }
            lastNamedPackage = name
            return [.installing(name: name)]
        }

        if let installed = value(after: "Installing ", in: rest) {
            return installingEvents(in: installed)
        }

        if let upgrading = value(after: "Upgrading ", in: rest) {
            let name = packageName(from: upgrading)
            guard isPackageName(name) else { return [] }
            lastNamedPackage = name
            return [.installing(name: name)]
        }

        if rest.hasPrefix("Pouring ") {
            return [.installing(name: lastNamedPackage)]
        }

        return []
    }

    /// `Installing dependencies for wget: openssl@3` belongs to wget's entry;
    /// `Installing wget dependency: openssl@3` is the same phase for wget.
    private mutating func installingEvents(in installed: String) -> [BrewProgressEvent] {
        if let dependencies = value(after: "dependencies for ", in: installed) {
            let name = packageName(from: dependencies)
            if isPackageName(name) { lastNamedPackage = name }
            return [.installing(name: lastNamedPackage ?? name)]
        }

        if let separator = installed.range(of: " dependency:") {
            let owner = packageName(from: String(installed[..<separator.lowerBound]))
            if isPackageName(owner) { lastNamedPackage = owner }
            return [.installing(name: lastNamedPackage ?? owner)]
        }

        let name = packageName(from: installed)
        guard isPackageName(name) else { return [.installing(name: lastNamedPackage)] }
        lastNamedPackage = name
        return [.installing(name: name)]
    }

    private mutating func successEvents(in line: String) -> [BrewProgressEvent] {
        let rest = line.drop { $0 == "🍺" || $0.isWhitespace }
        let firstToken = String(rest.prefix { !$0.isWhitespace })

        // The bottle summary names the package in its cellar path.
        if firstToken.contains("/Cellar/") {
            let parts = firstToken.split(separator: "/")
            if let cellar = parts.firstIndex(of: "Cellar"), parts.count > cellar + 1 {
                let name = String(parts[cellar + 1])
                if isPackageName(name) { return [.finished(name: name)] }
            }
        }

        let name = packageName(from: String(rest))
        guard isPackageName(name) else { return [] }
        return [.finished(name: name)]
    }

    // MARK: - Pieces

    private func value(after prefix: String, in text: String) -> String? {
        guard text.hasPrefix(prefix) else { return nil }
        return String(text.dropFirst(prefix.count))
    }

    /// A package name has no spaces and is not a bare number, so
    /// `Upgrading 3 outdated packages` does not become a package called "3".
    private func packageName(from rest: String) -> String {
        String(rest.prefix { !$0.isWhitespace && $0 != ":" })
    }

    private func isPackageName(_ name: String) -> Bool {
        !name.isEmpty && !name.allSatisfy(\.isNumber)
    }

    private func downloadFileName(from detail: String) -> String? {
        let token = String(detail.prefix { !$0.isWhitespace })
        guard !token.isEmpty else { return nil }
        guard token.lowercased().hasPrefix("http"), let url = URL(string: token) else {
            return token
        }

        let last = url.lastPathComponent
        // ghcr.io bottle URLs end in a digest under a "blobs" segment; the
        // package name is the segment above that, not "blobs".
        if last.hasPrefix("sha256:") || (last.count >= 32 && last.allSatisfy(\.isHexDigit)) {
            let parent = url.deletingLastPathComponent()
            let named = parent.lastPathComponent == "blobs"
                ? parent.deletingLastPathComponent().lastPathComponent
                : parent.lastPathComponent
            return named.isEmpty ? nil : named
        }
        return last.isEmpty ? nil : last
    }

    /// The last `<number>%` in the line. Progress bars often redraw the same
    /// line, so the last reading is the current one.
    private static func progressFraction(in line: String) -> Double? {
        guard let percent = line.lastIndex(of: "%") else { return nil }

        var start = percent
        while start > line.startIndex {
            let previous = line[line.index(before: start)]
            guard previous.isNumber || previous == "." else { break }
            start = line.index(before: start)
        }
        guard start < percent else { return nil }

        let number = String(line[start..<percent])
        guard let value = Double(number), value >= 0, value <= 100 else { return nil }
        return value / 100
    }
}
