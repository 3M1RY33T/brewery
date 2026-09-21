import Foundation

/// A browse shelf. Every catalog package lands in exactly one of these, apart
/// from `featured`, which is drawn from the most installed packages overall.
public enum CatalogCategory: String, CaseIterable, Identifiable {
    case featured
    case ai
    case developerTools
    case terminal
    case security
    case networking
    case data
    case media
    case fonts
    case design
    case productivity
    case communication
    case libraries
    case utilities

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .featured: return "Featured"
        case .ai: return "AI"
        case .developerTools: return "Developer Tools"
        case .terminal: return "Terminal"
        case .security: return "Security"
        case .networking: return "Networking"
        case .data: return "Data & Databases"
        case .media: return "Media"
        case .fonts: return "Fonts"
        case .design: return "Design"
        case .productivity: return "Productivity"
        case .communication: return "Communication"
        case .libraries: return "Libraries"
        case .utilities: return "Utilities"
        }
    }

    public var systemImage: String {
        switch self {
        case .featured: return "sparkles"
        case .ai: return "brain"
        case .developerTools: return "hammer"
        case .terminal: return "terminal"
        case .security: return "lock.shield"
        case .networking: return "network"
        case .data: return "cylinder.split.1x2"
        case .media: return "play.rectangle"
        case .fonts: return "textformat"
        case .design: return "paintbrush"
        case .productivity: return "checklist"
        case .communication: return "bubble.left.and.bubble.right"
        case .libraries: return "books.vertical"
        case .utilities: return "wrench.and.screwdriver"
        }
    }

    /// Categories a package can be assigned to, in priority order. `featured`
    /// is excluded: it is a ranking, not a subject, and `utilities` is the
    /// fallback for packages nothing else claims.
    public static var assignable: [CatalogCategory] {
        allCases.filter { $0 != .featured && $0 != .utilities }
    }

    /// Whole words that must appear as their own token.
    ///
    /// Matching `"ai"` as a substring would claim "email", "maintain" and
    /// "chain", so short, ambiguous terms are only ever matched as words.
    var keywords: Set<String> {
        switch self {
        case .featured, .utilities:
            return []
        case .ai:
            return ["ai", "llm", "llms", "gpt", "nlp", "chatbot", "chatbots"]
        case .developerTools:
            return ["ide", "sdk", "compiler", "debugger", "linter", "git", "repl", "api", "cmake", "lsp"]
        case .terminal:
            return ["cli", "shell", "terminal", "tui", "zsh", "bash", "fish", "tmux", "prompt", "pager", "ssh"]
        case .security:
            return ["vpn", "tls", "ssl", "gpg", "pgp", "otp", "2fa", "antivirus", "firewall", "keychain", "sandbox"]
        case .networking:
            return ["dns", "http", "https", "tcp", "udp", "ftp", "proxy", "packet", "port", "ip", "socket"]
        case .data:
            return ["sql", "database", "databases", "postgres", "postgresql", "mysql", "sqlite", "redis", "mongodb", "json", "yaml", "csv", "etl"]
        case .media:
            return ["video", "audio", "music", "photo", "photos", "image", "images", "player", "codec", "podcast", "camera", "subtitle", "subtitles"]
        case .fonts:
            return ["font", "fonts", "typeface", "typefaces", "glyphs"]
        case .design:
            return ["icon", "icons", "svg", "cad", "3d", "ui", "ux"]
        case .productivity:
            return ["note", "notes", "calendar", "todo", "task", "tasks", "pdf", "office", "markdown", "wiki", "email"]
        case .communication:
            return ["chat", "browser", "browsers", "messaging", "messenger", "irc", "sms", "voip", "mail"]
        case .libraries:
            return ["library", "libraries", "framework", "bindings", "runtime", "headers", "toolkit"]
        }
    }

    /// Longer, unambiguous terms matched anywhere in the text.
    var phrases: [String] {
        switch self {
        case .featured, .utilities:
            return []
        case .ai:
            return ["machine learning", "artificial intelligence", "neural", "deep learning",
                    "language model", "openai", "anthropic", "copilot", "transformer",
                    "inference", "chatgpt", "embedding"]
        case .developerTools:
            return ["developer", "development", "compile", "debug", "version control",
                    "code editor", "source code", "package manager", "build tool",
                    "testing framework", "programming", "refactor", "container",
                    "kubernetes", "devops", "microservice"]
        case .terminal:
            return ["command-line", "command line", "terminal emulator", "shell script", "dotfiles"]
        case .security:
            return ["security", "encrypt", "decrypt", "password", "cryptograph", "vulnerab",
                    "malware", "privacy", "authentication", "certificate", "secrets", "penetration"]
        case .networking:
            return ["network", "tunnel", "bandwidth", "web server", "load balanc", "protocol"]
        case .data:
            return ["data analysis", "data science", "query engine", "key-value",
                    "time series", "spreadsheet", "analytics", "dataset"]
        case .media:
            return ["streaming", "stream", "screenshot", "screen record", "media player",
                    "transcode", "playback", "multimedia"]
        case .fonts:
            return ["nerd font", "monospaced font", "typeface", "font family"]
        case .design:
            return ["design", "graphic", "vector", "illustration", "typography",
                    "wireframe", "prototyping", "animation", "render"]
        case .productivity:
            return ["productivity", "document", "writing", "note-taking", "time track",
                    "presentation", "knowledge base", "reminder"]
        case .communication:
            return ["web browser", "video call", "conferenc", "collaboration",
                    "instant messag", "social network", "video meeting"]
        case .libraries:
            return ["shared library", "c library", "implementation of", "api for", "utility functions"]
        }
    }

    /// How strongly `package` belongs here. Zero means no claim.
    func score(tokens: Set<String>, text: String) -> Int {
        let wordHits = keywords.intersection(tokens).count
        let phraseHits = phrases.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
        return wordHits + phraseHits
    }
}
