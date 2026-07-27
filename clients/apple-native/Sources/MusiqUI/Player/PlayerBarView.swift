import SwiftUI

/// The Apple counterpart to the desktop's floating Acrylic/Vibrancy player
/// bar: a `.thickMaterial` capsule floating above content, using native
/// spring animation (rather than the desktop's CSS `--ease-emphasized`
/// cubic-bezier approximation) for the same "expand seekbar on interaction,
/// blur everything else" language.
struct PlayerBarView: View {
    @State private var scrubbing = false
    @State private var progress: Double = 0.32

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.linearGradient(colors: [.accentColor.opacity(0.5), .secondary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .blur(radius: scrubbing ? 6 : 0)
                .opacity(scrubbing ? 0.5 : 1)

            ProgressView(value: progress)
                .frame(height: scrubbing ? 44 : 4)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            scrubbing = true
                            progress = min(1, max(0, value.location.x / 260))
                        }
                        .onEnded { _ in scrubbing = false }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrubbing)

            HStack(spacing: 16) {
                Image(systemName: "backward.fill")
                Image(systemName: "play.fill")
                Image(systemName: "forward.fill")
            }
            .blur(radius: scrubbing ? 6 : 0)
            .opacity(scrubbing ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 16, y: 6)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrubbing)
    }
}
