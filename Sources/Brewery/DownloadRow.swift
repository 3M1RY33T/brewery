import BreweryCore
import SwiftUI

/// One package in a live run, shared by the Browse popover and the Library.
///
/// The bar is phase-driven when Homebrew gives no percentage, so it always
/// moves; the item's own fraction takes over as soon as one appears.
struct DownloadRow: View {
    let item: DownloadItem
    /// Browse has the catalog for icons of packages not installed yet;
    /// Library passes nothing and falls back to the kind glyph.
    var catalogStore: CatalogStore?
    /// Present only for entries the user may remove, which is the queue.
    var onRemove: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                DownloadIcon(item: item, catalogStore: catalogStore, size: 28, cornerRadius: 7)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(status)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                if let onRemove, item.phase == .queued {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Remove this action from the queue")
                } else {
                    stateGlyph
                }
            }

            DownloadProgressBar(item: item)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Pieces

    private var status: String {
        guard item.phase == .downloading, let detail = item.detail, !detail.isEmpty else {
            return item.statusText
        }
        return "\(item.statusText) · \(detail)"
    }

    private var statusColor: Color {
        switch item.phase {
        case .failed: return .red
        case .finished: return .green
        default: return .secondary
        }
    }

    @ViewBuilder
    private var stateGlyph: some View {
        switch item.phase {
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(.red)
        case .skipped:
            Image(systemName: "minus.circle")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        default:
            EmptyView()
        }
    }
}
