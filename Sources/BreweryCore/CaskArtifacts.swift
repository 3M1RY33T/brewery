import Foundation

/// The part of a cask's `artifacts` array Brewery reads.
///
/// Homebrew publishes no icon for a cask, but a cask that installs an app
/// declares the bundle it lands in Applications as, and that bundle carries the
/// real icon. `artifacts` is a heterogeneous array of single-key objects
/// (`app`, `pkg`, `font`, `zap`, ...), so every shape that is not the `app`
/// entry is skipped rather than treated as an error.
struct CaskArtifacts: Decodable, Equatable {
    let appBundleName: String?

    init(appBundleName: String?) {
        self.appBundleName = appBundleName
    }

    init(from decoder: Decoder) throws {
        guard var unkeyed = try? decoder.unkeyedContainer() else {
            appBundleName = nil
            return
        }

        var bundleName: String?
        while !unkeyed.isAtEnd {
            guard let entry = try? unkeyed.decode(CaskArtifactEntry.self) else {
                _ = try? unkeyed.decode(IgnoredJSONValue.self)
                continue
            }
            if bundleName == nil {
                bundleName = entry.appBundleName
            }
        }
        appBundleName = bundleName
    }
}

/// One element of `artifacts`. Never throws, so decoding always consumes the
/// element and the enclosing loop cannot stall on an unrecognised shape.
private struct CaskArtifactEntry: Decodable {
    let appBundleName: String?

    init(from decoder: Decoder) throws {
        guard let keyed = try? decoder.container(keyedBy: DynamicCodingKey.self),
              let appKey = DynamicCodingKey(stringValue: "app"),
              keyed.contains(appKey) else {
            appBundleName = nil
            return
        }
        appBundleName = (try? keyed.decode(CaskAppArtifact.self, forKey: appKey))?.bundleName
    }
}

/// The value of an `app` artifact: a list whose entries are either the bundle
/// name (`"Firefox.app"`) or an object naming it (`{"target": "Firefox.app"}`).
private struct CaskAppArtifact: Decodable {
    let bundleName: String?

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let value = try? single.decode(String.self) {
            bundleName = CaskAppArtifact.normalizedBundleName(value)
            return
        }

        guard var unkeyed = try? decoder.unkeyedContainer() else {
            bundleName = nil
            return
        }

        var name: String?
        while !unkeyed.isAtEnd {
            guard let entry = try? unkeyed.decode(CaskAppArtifactEntry.self) else {
                _ = try? unkeyed.decode(IgnoredJSONValue.self)
                continue
            }
            if name == nil, let value = entry.value {
                name = CaskAppArtifact.normalizedBundleName(value)
            }
        }
        bundleName = name
    }

    /// Reduces whatever the cask declared to a bare bundle name. Entries that
    /// interpolate a Homebrew variable (`$APPDIR/...`) cannot be resolved
    /// without running brew, so they are dropped.
    static func normalizedBundleName(_ value: String) -> String? {
        guard !value.contains("$") else { return nil }
        let name = (value as NSString).lastPathComponent
        guard name.hasSuffix(".app") else { return nil }
        return name
    }
}

private struct CaskAppArtifactEntry: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let string = try? single.decode(String.self) {
            value = string
            return
        }
        if let keyed = try? decoder.container(keyedBy: DynamicCodingKey.self),
           let targetKey = DynamicCodingKey(stringValue: "target") {
            value = try? keyed.decode(String.self, forKey: targetKey)
            return
        }
        value = nil
    }
}
