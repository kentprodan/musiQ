plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.musiq.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.musiq.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation(project(":musiq-ffi"))

    val composeBom = platform("androidx.compose:compose-bom:2024.10.01")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material3:material3-window-size-class")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.navigation:navigation-compose:2.8.3")
    implementation("androidx.media3:media3-session:1.4.1")

    // Android TV: Material-for-TV components (focus-aware Card/Button,
    // D-Pad-first navigation primitives) used under ui/tv/.
    implementation("androidx.tv:tv-material:1.0.0")
    implementation("androidx.tv:tv-foundation:1.0.0")
}
