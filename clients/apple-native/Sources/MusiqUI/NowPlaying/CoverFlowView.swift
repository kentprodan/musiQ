import SwiftUI

/// SwiftUI counterpart to the desktop `CoverFlow.tsx`: same algorithm
/// (frontal center item, flanking items rotated/receded/dimmed by
/// distance), expressed with `rotation3DEffect` + `.offset` instead of
/// CSS 3D transforms. Swipe-driven on iOS, scroll-wheel/trackpad-driven
/// via `.gesture(DragGesture)` on macOS Catalyst/visionOS pointer input.
public struct CoverFlowView: View {
    @State private var centerIndex: Int = 0
    private let albumCount = 14

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            GeometryReader { geo in
                ZStack {
                    ForEach(visibleRange, id: \.self) { index in
                        let offset = index - centerIndex
                        CoverFlowTile(isCenter: offset == 0)
                            .frame(width: min(geo.size.width * 0.32, 280))
                            .rotation3DEffect(
                                .degrees(offset == 0 ? 0 : (offset < 0 ? 55 : -55)),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: offset < 0 ? .trailing : .leading
                            )
                            .offset(x: CGFloat(offset) * 110)
                            .scaleEffect(offset == 0 ? 1 : 0.82)
                            .brightness(offset == 0 ? 0 : -0.15 * Double(abs(offset)))
                            .opacity(max(0, 1 - Double(abs(offset)) * 0.16))
                            .zIndex(Double(100 - abs(offset)))
                            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: centerIndex)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(height: 340)

            Text("Album \(centerIndex + 1)").font(.headline)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let step = value.translation.width < -60 ? 1 : (value.translation.width > 60 ? -1 : 0)
                    centerIndex = max(0, min(albumCount - 1, centerIndex + step))
                }
        )
    }

    private var visibleRange: [Int] {
        let lo = max(0, centerIndex - 5)
        let hi = min(albumCount - 1, centerIndex + 5)
        return Array(lo...hi)
    }
}

private struct CoverFlowTile: View {
    let isCenter: Bool

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.linearGradient(colors: [.accentColor.opacity(0.55), .secondary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .aspectRatio(1, contentMode: .fit)
                .shadow(radius: isCenter ? 24 : 8, y: 12)

            // Mirror reflection, faded via a bottom-anchored gradient mask.
            RoundedRectangle(cornerRadius: 10)
                .fill(.linearGradient(colors: [.accentColor.opacity(0.55), .secondary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .aspectRatio(2.6, contentMode: .fit)
                .scaleEffect(y: -1)
                .mask(LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
        }
    }
}
