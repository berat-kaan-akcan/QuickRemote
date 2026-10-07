import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Release signing uses the phone app's key (quick_remote_app/android/key.properties,
// storeFile relative to quick_remote_app/android/app): Play serves both apps
// from one listing, and a later phone-watch link (Wearable Data Layer) only
// pairs apps signed with the same key. Without it release builds fall back
// to the debug key, which Play Console rejects.
val phoneAndroidDir = rootProject.file("../quick_remote_app/android")
val keystoreProperties = Properties().apply {
    val file = phoneAndroidDir.resolve("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}
val hasReleaseKey = !keystoreProperties.isEmpty

// A store upload (an app bundle) must never go out with the debug key, so
// bundling stops without key.properties; a release APK for a test phone
// only gets a warning.
if (!hasReleaseKey) {
    gradle.taskGraph.whenReady {
        val names = allTasks.filter { it.project == project }.map { it.name }
        if ("bundleRelease" in names) {
            throw GradleException("key.properties is missing: a release app bundle would be signed with the debug key.")
        }
        if ("assembleRelease" in names) {
            logger.warn("WARNING: key.properties is missing, this release build is signed with the debug key.")
        }
    }
}

android {
    namespace = "com.quickremote.wear"
    // Wear Compose 1.7 compiles against SDK 37.
    compileSdk = 37

    defaultConfig {
        // The phone app's id: one Play listing serves both. It can still
        // change before the first Play release, together with the phone's.
        applicationId = "com.quickremote.quick_remote_app"
        // Wear OS 3, the oldest Wear OS on the Galaxy Watch 4 and later.
        minSdk = 30
        targetSdk = 36
        // Every AAB in one Play listing needs its own versionCode: the watch
        // is 1_000_000 + the phone's (quick_remote_app/pubspec.yaml, 0.1.0+1).
        versionCode = 1_000_001
        versionName = "0.1.0"
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = phoneAndroidDir.resolve("app").resolve(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.09.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material:material-icons-core:1.7.8")
    implementation("androidx.wear.compose:compose-material3:1.7.0")
    implementation("androidx.wear.compose:compose-foundation:1.7.0")
    implementation("androidx.wear.compose:compose-navigation:1.7.0")
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
    implementation("androidx.core:core-ktx:1.19.1")

    testImplementation("junit:junit:4.13.2")
}
