import Foundation

public struct PackageNodeID: Hashable, Codable, Identifiable, Comparable {
    public let kind: PackageKind
    public let name: String

    public var id: String { "\(kind.rawValue):\(name)" }

    public init(kind: PackageKind, name: String) {
        self.kind = kind
        self.name = name
    }

    public static func < (lhs: PackageNodeID, rhs: PackageNodeID) -> Bool {
        if lhs.name != rhs.name {
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return lhs.kind.rawValue < rhs.kind.rawValue
    }
}

public enum DependencyRelationship: String, Codable, Equatable {
    case direct
    case runtime
    case caskDeclared
}

public struct DependencyEdge: Hashable, Codable {
    public let from: PackageNodeID
    public let to: PackageNodeID
    public let relationship: DependencyRelationship

    public init(from: PackageNodeID, to: PackageNodeID, relationship: DependencyRelationship) {
        self.from = from
        self.to = to
        self.relationship = relationship
    }
}

public struct BrewDependencyGraph: Equatable {
    public let nodes: Set<PackageNodeID>
    public let forwardEdges: [PackageNodeID: [DependencyEdge]]
    public let reverseEdges: [PackageNodeID: [DependencyEdge]]

    public init(nodes: Set<PackageNodeID>, edges: [DependencyEdge]) {
        self.nodes = nodes
        self.forwardEdges = Dictionary(grouping: edges, by: \.from)
            .mapValues { $0.sorted(by: Self.edgeSort) }
        self.reverseEdges = Dictionary(grouping: edges, by: \.to)
            .mapValues { $0.sorted(by: Self.edgeSort) }
    }

    public static let empty = BrewDependencyGraph(nodes: [], edges: [])

    public func directDependencies(of node: PackageNodeID) -> [PackageNodeID] {
        uniqueSortedNodes((forwardEdges[node] ?? [])
            .filter(\.isDirectRelationship)
            .map(\.to))
    }

    public func recursiveDependencies(of node: PackageNodeID) -> [PackageNodeID] {
        traverse(from: node, using: forwardEdges, target: \.to)
    }

    public func directDependents(of node: PackageNodeID) -> [PackageNodeID] {
        uniqueSortedNodes((reverseEdges[node] ?? [])
            .filter(\.isDirectRelationship)
            .map(\.from))
    }

    public func recursiveDependents(of node: PackageNodeID) -> [PackageNodeID] {
        traverse(from: node, using: reverseEdges, target: \.from)
    }

    public func isLeaf(_ node: PackageNodeID) -> Bool {
        directDependents(of: node).isEmpty
    }

    public func isRequiredByInstalledPackage(_ node: PackageNodeID) -> Bool {
        !directDependents(of: node).isEmpty
    }

    public func contains(_ node: PackageNodeID) -> Bool {
        nodes.contains(node)
    }

    private func traverse(
        from root: PackageNodeID,
        using adjacency: [PackageNodeID: [DependencyEdge]],
        target: KeyPath<DependencyEdge, PackageNodeID>
    ) -> [PackageNodeID] {
        var visited: Set<PackageNodeID> = [root]
        var result: [PackageNodeID] = []
        var stack = adjacency[root]?.map { $0[keyPath: target] } ?? []

        while let node = stack.popLast() {
            guard !visited.contains(node) else { continue }
            visited.insert(node)
            result.append(node)
            stack.append(contentsOf: adjacency[node]?.map { $0[keyPath: target] } ?? [])
        }

        return uniqueSortedNodes(result)
    }

    private func uniqueSortedNodes(_ nodes: [PackageNodeID]) -> [PackageNodeID] {
        Array(Set(nodes)).sorted()
    }

    private static func edgeSort(_ lhs: DependencyEdge, _ rhs: DependencyEdge) -> Bool {
        if lhs.to != rhs.to {
            return lhs.to < rhs.to
        }
        if lhs.from != rhs.from {
            return lhs.from < rhs.from
        }
        return lhs.relationship.rawValue < rhs.relationship.rawValue
    }
}

private extension DependencyEdge {
    var isDirectRelationship: Bool {
        relationship == .direct || relationship == .caskDeclared
    }
}

public struct BrewInventory: Equatable {
    public let packages: [BrewPackage]
    public let graph: BrewDependencyGraph

    public init(packages: [BrewPackage], graph: BrewDependencyGraph) {
        self.packages = packages
        self.graph = graph
    }
}
