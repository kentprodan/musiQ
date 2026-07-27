// Placeholder for the UniFFI-generated Swift bindings.
//
// Once `core/musiq-ffi` builds for an Apple target (via `cargo build
// --target aarch64-apple-ios` etc., wrapped in an XCFramework), run:
//
//   uniffi-bindgen generate core/musiq-ffi/src/musiq.udl \
//     --language swift --out-dir clients/apple-native/Sources/MusiqFFI
//
// which overwrites this file with the real `MusiqPlayer` class, matching
// the `interface MusiqPlayer` declared in `musiq.udl`. Declared here by
// hand so `MusiqUI` has something concrete to compile against before the
// Rust side is wired into an Xcode build phase.

import Foundation

public enum PlaybackState: String {
    case stopped, playing, paused, buffering
}

public struct FfiTrack: Identifiable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let durationMs: UInt64
}

public protocol PlaybackObserver: AnyObject {
    func onStateChanged(_ state: PlaybackState)
    func onPositionChanged(_ positionMs: UInt64)
    func onTrackChanged(_ track: FfiTrack)
}

public final class MusiqPlayer {
    public init(libraryDbPath: String) {}

    public func play() {}
    public func pause() {}
    public func seek(positionMs: UInt64) {}
    public func skipNext() {}
    public func skipPrevious() {}
    public func setVolume(_ volume: Float) {}
    public func listQueue() -> [FfiTrack] { [] }
    public func registerObserver(_ observer: PlaybackObserver) {}
}
