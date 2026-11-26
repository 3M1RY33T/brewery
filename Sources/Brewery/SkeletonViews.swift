import SwiftUI

/// A placeholder block with a light sweeping across it, so a page that is
/// still loading reads as loading rather than empty. Reduce Motion keeps the
/// block and drops the sweep.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 5

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.primary.opacity(0.08))
            .frame(width: width, height: height)
            .modifier(Shimmer())
    }
}

private struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSweeping = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let width = max(geometry.size.width, 1)
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0),
                            Color.primary.opacity(0.13),
                            Color.primary.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.6)
                    .offset(x: isSweeping ? width : -width * 0.6)
                }
                .allowsHitTesting(false)
                .mask(content)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    isSweeping = true
                }
            }
    }
}

/// Browse before its first catalog load: the same shapes and padding as the
/// real shelves, so the page does not jump when the data lands.
struct BrowseSkeletonView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 34) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonBlock(width: 460, height: 168, cornerRadius: 14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(width: 190, height: 24)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonBlock(height: 64, cornerRadius: 11)
                    }
                }
            }
            .padding(.horizontal, 16)

            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBlock(width: 210, height: 24)
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                SkeletonBlock(width: 240, height: 190, cornerRadius: 8)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    VStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonBlock(height: 42, cornerRadius: 8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.bottom, 24)
        .accessibilityHidden(true)
    }
}

/// Library before its first inventory load.
struct LibrarySkeletonView: View {
    var body: some View {
        ScrollView {
            librarySkeletonContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    /// The skeleton's content without the scrolling wrapper, so the offscreen
    /// verification harness can lay it out (ImageRenderer cannot lay out a
    /// ScrollView). The live window uses `body`, which wraps this in a
    /// ScrollView.
    var librarySkeletonContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(width: 130, height: 24)

                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonBlock(width: 240, height: 190, cornerRadius: 8)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 130, height: 24)

                ForEach(0..<6, id: \.self) { _ in
                    SkeletonBlock(height: 44, cornerRadius: 8)
                }
            }
        }
        .padding(16)
    }
}
