// swift-tools-version: 5.9
import PackageDescription

/// Shared Swift code for every Apple target (iOS, iPadOS, tvOS, watchOS,
/// visionOS). Each platform still needs its own thin Xcode *app* target
/// (Info.plist, entitlements, App Store metadata differ per platform) —
/// this package only holds the code those targets share, so the
/// SwiftUI views and the UniFFI bridge can only drift in one place.
///
/// `MusiqFFI` wraps the bindings generated from `core/musiq-ffi` by:
///   uniffi-bindgen generate --library target/.../libmusiq_ffi.dylib \
///     --language swift --out-dir clients/apple-native/Sources/MusiqFFI
/// (run once per `musiq.udl` change; the generated `musiq.swift` +
/// `musiqFFI.h`/`.modulemap` are checked in, not regenerated at build time,
/// so Xcode doesn't need the Rust toolchain to open the project).
let package = Package(
    name: "MusiqApple",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "MusiqFFI", targets: ["MusiqFFI"]),
        .library(name: "MusiqUI", targets: ["MusiqUI"]),
    ],
    targets: [
        .target(name: "MusiqFFI"),
        .target(name: "MusiqUI", dependencies: ["MusiqFFI"]),
    ]
)
