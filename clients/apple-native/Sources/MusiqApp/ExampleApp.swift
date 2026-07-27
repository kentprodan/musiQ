// Not a compiled target — SPM can't produce an installable iOS/tvOS/
// watchOS/visionOS app bundle (no Info.plist, code signing, or asset
// catalog support), so each platform needs a real Xcode App target.
//
// This file is the pattern every one of those targets follows: a few
// lines that pull in `MusiqUI` and nothing else, so app-specific Xcode
// concerns (capabilities, entitlements, App Store metadata) never leak
// into shared view code.
//
//   1. File > New > Project > App, once per platform (iOS, tvOS,
//      watchOS, visionOS).
//   2. File > Add Package Dependencies... > Add Local... > this folder.
//   3. Link `MusiqUI` (and transitively `MusiqFFI`) to the new target.
//   4. Replace the generated `@main` App struct's body with the one below.

import SwiftUI
import MusiqUI

struct MusiqApp: App {
    var body: some Scene {
        WindowGroup {
            MusiqRootView()
        }
    }
}
