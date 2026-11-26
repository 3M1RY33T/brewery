import Foundation

/// Where one package in a running action has got to.
///
/// Homebrew does not report a download percentage reliably: when its output is
/// a pipe, curl may print only the phase line. Every phase therefore carries
/// a fallback fraction, so a bar built from phases alone still advances.
public enum DownloadPhase: String, Equatable, CaseIterable {
    case queued
    case fetching
    case downloading
    case installing
    case finished
    case failed
    case skipped

    public var title: String {
        switch self {
        case .queued: return "Queued"
        case .fetching: return "Fetching"
        case .downloading: return "Downloading"
        case .installing: return "Installing"
        case .finished: return "Finished"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        }
    }

    /// Where the bar sits when no real percentage has been seen.
    public var fallbackFraction: Double {
        switch self {
        case .queued: return 0
        case .fetching: return 0.15
        case .downloading: return 0.45
        case .installing: return 0.8
        case .finished, .failed, .skipped: return 1
        }
    }

    public var isSettled: Bool {
        self == .finished || self == .failed || self == .skipped
    }

    /// The command is working on this item now.
    public var isActive: Bool {
        self == .fetching || self == .downloading || self == .installing
    }
}

/// One package — or, for `brew update` and `brew cleanup`, the action itself —
/// moving through a run.
public struct DownloadItem: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    /// Nil for an action with no packages of its own, such as cleanup.
    public let kind: PackageKind?
    public internal(set) var phase: DownloadPhase
    /// The real download percentage when Homebrew reported one.
    public internal(set) var fraction: Double?
    /// Secondary text from the output, such as the file being downloaded.
    public internal(set) var detail: String?

    public init(name: String, kind: PackageKind?, phase: DownloadPhase = .queued) {
        self.id = UUID()
        self.name = name
        self.kind = kind
        self.phase = phase
    }

    public var isSettled: Bool { phase.isSettled }

    /// This item's own fill, 0...1.
    public var progress: Double {
        if let fraction, !isSettled {
            return min(max(fraction, 0), 1)
        }
        return phase.fallbackFraction
    }

    /// The state line beside the name.
    public var statusText: String {
        switch phase {
        case .downloading:
            guard let fraction else { return "Downloading" }
            return "Downloading \(Int((fraction * 100).rounded()))%"
        case .failed:
            guard let detail, !detail.isEmpty else { return "Failed" }
            return "Failed: \(detail)"
        default:
            return phase.title
        }
    }
}

/// One run of the queue: every action started while the user was in a batch,
/// with its packages in the order they will run.
///
/// The session owns no timing and starts nothing. `PackageStore` creates it,
/// activates one action's items at a time, settles them, and decides when the
/// session is cleared.
public struct DownloadSession: Identifiable, Equatable {
    public let id: UUID
    /// The first action in the batch; the header names it while it runs.
    public let actionTitle: String
    public private(set) var items: [DownloadItem]
    /// The item the command is working on now. Nil between actions and after
    /// the run ends.
    public private(set) var currentItemID: DownloadItem.ID?
    /// Set when an action failed, and left set until the session is dismissed.
    public private(set) var failedMessage: String?

    /// Items belonging to the action running now, so a failure or success
    /// settles exactly that action and leaves the queue behind it alone.
    private var activeItemIDs: [DownloadItem.ID] = []

    public init(action: BrewAction) {
        self.id = UUID()
        self.actionTitle = action.title
        self.items = DownloadSession.items(for: action)
    }

    public var isRunning: Bool { currentItemID != nil }

    /// Every item has settled and nothing is running: the run is over, and the
    /// store may clear it once it has been on screen long enough.
    public var isLingering: Bool {
        currentItemID == nil && !items.isEmpty && items.allSatisfy(\.isSettled)
    }

    public var activeItem: DownloadItem? {
        guard let currentItemID else { return nil }
        return items.first { $0.id == currentItemID }
    }

    /// Running plus waiting entries, the number the Downloads button badges.
    public var activeCount: Int { items.filter { !$0.isSettled }.count }

    public var hasFailure: Bool { failedMessage != nil }

    /// The whole run's progress: settled items count whole, the running one by
    /// its own fraction.
    public var fraction: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0.0) { $0 + $1.progress } / Double(items.count)
    }

    /// Packages behind the running one, for the popover's queue.
    public var queuedItems: [DownloadItem] { items.filter { $0.phase == .queued } }

    // MARK: - Queue

    /// Adds a later action's packages as queued entries.
    @discardableResult
    public mutating func append(action: BrewAction) -> [DownloadItem.ID] {
        let added = DownloadSession.items(for: action)
        items.append(contentsOf: added)
        return added.map(\.id)
    }

    /// Makes one action's items the active set, with its first package
    /// fetching.
    public mutating func activate(_ ids: [DownloadItem.ID]) {
        activeItemIDs = ids
        guard let next = ids.first(where: { id in
            items.first { $0.id == id }?.isSettled == false
        }) else {
            currentItemID = nil
            return
        }
        currentItemID = next
        if let index = index(of: next), items[index].phase == .queued {
            items[index].phase = .fetching
        }
    }

    /// Settles the action running now. A failure fails the package the command
    /// was on and skips the rest of that action's packages, so the actions
    /// queued behind it still run.
    public mutating func settleActiveAction(succeeded: Bool, message: String?) {
        if succeeded {
            for id in activeItemIDs where index(of: id).map({ !items[$0].isSettled }) == true {
                guard let index = index(of: id) else { continue }
                items[index].phase = .finished
                items[index].fraction = 1
            }
        } else {
            if let currentItemID, let index = index(of: currentItemID), !items[index].isSettled {
                items[index].phase = .failed
                items[index].detail = message
                items[index].fraction = 1
            }
            for id in activeItemIDs where index(of: id).map({ !items[$0].isSettled }) == true {
                guard let index = index(of: id) else { continue }
                items[index].phase = .skipped
                items[index].fraction = 1
            }
            if let message, !message.isEmpty {
                failedMessage = message
            } else if failedMessage == nil {
                failedMessage = "The command failed"
            }
        }
        currentItemID = nil
        activeItemIDs = []
    }

    /// Drops entries the user removed from the queue. A running item is never
    /// removed, whatever ids arrive.
    public mutating func remove(itemsWith ids: Set<DownloadItem.ID>) {
        let removable = items.filter { ids.contains($0.id) && $0.phase == .queued }.map(\.id)
        guard !removable.isEmpty else { return }
        let removed = Set(removable)
        items.removeAll { removed.contains($0.id) }
        activeItemIDs.removeAll { removed.contains($0) }
    }

    // MARK: - Events

    /// Applies one parsed line of Homebrew output.
    public mutating func apply(_ event: BrewProgressEvent) {
        switch event {
        case .fetching(let name):
            move(to: .fetching, name: name, detail: nil)
        case .downloading(let name, let detail):
            move(to: .downloading, name: name, detail: detail)
        case .installing(let name):
            move(to: .installing, name: name, detail: nil)
        case .progress(let value):
            guard let index = currentIndex, !items[index].isSettled else { return }
            items[index].fraction = min(max(value, 0), 1)
            if items[index].phase == .queued || items[index].phase == .fetching {
                items[index].phase = .downloading
            }
        case .finished(let name):
            guard let index = index(matching: name) ?? currentIndex, !items[index].isSettled else { return }
            items[index].phase = .finished
            items[index].fraction = 1
            advance(after: index)
        case .failed(let message):
            if let index = currentIndex, !items[index].isSettled {
                items[index].phase = .failed
                items[index].detail = message
            }
            if !message.isEmpty {
                failedMessage = message
            }
        }
    }

    // MARK: - Helpers

    private static func items(for action: BrewAction) -> [DownloadItem] {
        let targets = action.targets
        guard !targets.isEmpty else {
            return [DownloadItem(name: action.title, kind: nil, phase: .queued)]
        }
        return targets.map { DownloadItem(name: $0.name, kind: $0.kind) }
    }

    private var currentIndex: Int? {
        guard let currentItemID else { return nil }
        return index(of: currentItemID)
    }

    private func index(of id: DownloadItem.ID) -> Int? {
        items.firstIndex { $0.id == id }
    }

    /// Among the active action's items only: an action queued behind this one
    /// may name the same package, and its entry must stay queued.
    private func index(matching name: String?) -> Int? {
        guard let name, !name.isEmpty else { return nil }
        return items.firstIndex { item in
            activeItemIDs.contains(item.id) && item.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private mutating func move(to phase: DownloadPhase, name: String?, detail: String?) {
        guard let target = index(matching: name) ?? currentIndex else { return }
        // Output can arrive just after the action settled; it must not bring a
        // finished entry back to life.
        guard !items[target].isSettled else { return }

        if target != currentIndex, let currentIndex, !items[currentIndex].isSettled {
            items[currentIndex].phase = .finished
            items[currentIndex].fraction = 1
        }
        currentItemID = items[target].id
        items[target].phase = phase
        if let detail {
            items[target].detail = detail
        }
    }

    /// Moves to the next unsettled package in this action, or to none when the
    /// action's last package has settled.
    private mutating func advance(after index: Int) {
        guard let position = activeItemIDs.firstIndex(of: items[index].id) else {
            currentItemID = nil
            return
        }
        for id in activeItemIDs[(position + 1)...] {
            guard let next = self.index(of: id), !items[next].isSettled else { continue }
            currentItemID = id
            items[next].phase = .fetching
            return
        }
        currentItemID = nil
    }
}
