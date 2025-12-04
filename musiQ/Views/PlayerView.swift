import SwiftUI

/// SwiftUI player controls and chrome
struct PlayerView: View {
    @ObservedObject var audioEngine = AudioEngine.shared
    @State private var isVolumeHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Track info bar
            HStack {
                // Album art
                albumArtwork
                    .frame(width: 60, height: 60)
                    .cornerRadius(4)
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioEngine.currentTrack?.title ?? "No Track Playing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(audioEngine.currentTrack?.artist ?? "-")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: 250, alignment: .leading)
                
                Spacer()
                
                // Playback controls
                playbackControls
                
                Spacer()
                
                // Volume control
                volumeControl
                    .frame(width: 150)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Progress bar
            progressBar
                .frame(height: 6)
        }
        .frame(height: 88)
    }
    
    // MARK: - Album Artwork
    private var albumArtwork: some View {
        ZStack {
            if let track = audioEngine.currentTrack {
                // TODO: Load actual album art
                Color.gray.opacity(0.3)
                Image(systemName: "music.note")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            } else {
                Color.gray.opacity(0.2)
                Image(systemName: "music.note")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
    }
    
    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 20) {
            // Previous
            Button(action: previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Play/Pause
            Button(action: togglePlayPause) {
                Image(systemName: audioEngine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Next
            Button(action: nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Volume Control
    private var volumeControl: some View {
        HStack(spacing: 8) {
            Image(systemName: volumeIcon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Slider(value: Binding(
                get: { Double(audioEngine.volume) },
                set: { audioEngine.setVolume(Float($0)) }
            ), in: 0...1)
            .controlSize(.small)
        }
    }
    
    private var volumeIcon: String {
        if audioEngine.volume == 0 {
            return "speaker.slash.fill"
        } else if audioEngine.volume < 0.33 {
            return "speaker.fill"
        } else if audioEngine.volume < 0.66 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                // Progress
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: progressWidth(in: geometry.size.width))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let progress = value.location.x / geometry.size.width
                        let seekTime = progress * audioEngine.duration
                        audioEngine.seek(to: max(0, min(seekTime, audioEngine.duration)))
                    }
            )
            .overlay(
                HStack {
                    Text(formatTime(audioEngine.currentTime))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Text(formatTime(audioEngine.duration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
                .offset(y: -10)
            )
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard audioEngine.duration > 0 else { return 0 }
        let progress = audioEngine.currentTime / audioEngine.duration
        return totalWidth * CGFloat(progress)
    }
    
    // MARK: - Actions
    private func togglePlayPause() {
        if audioEngine.isPlaying {
            audioEngine.pause()
        } else if audioEngine.currentTrack != nil {
            audioEngine.resume()
        }
    }
    
    private func previousTrack() {
        // TODO: Implement previous track logic
        print("⏮ Previous track")
    }
    
    private func nextTrack() {
        // TODO: Implement next track logic
        print("⏭ Next track")
    }
    
    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
            .frame(width: 800)
    }
}
