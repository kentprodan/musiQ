plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.musiq.ffi"
    compileSdk = 35

    defaultConfig {
        minSdk = 26 // musiq-audio-engine's decode path targets API 26+ (oboe/AAudio baseline)
    }

    // The real module also declares an `externalNativeBuild`/`jniLibs.srcDirs`
    // pointing at the `.so` produced by:
    //   cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 \
    //     -o musiq-ffi/src/main/jniLibs build --release -p musiq-ffi
    // Left out of this scaffold since it depends on the NDK toolchain
    // being installed, not on anything Kotlin/Gradle-side.
}

dependencies {
    implementation("net.java.dev.jna:jna:5.14.0@aar")
}
