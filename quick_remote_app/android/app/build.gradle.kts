import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (gitignored, like the keystore):
// storeFile, storePassword, keyAlias, keyPassword. Without it release APKs
// fall back to the debug key (see below for app bundles).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
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
    namespace = "com.quickremote.quick_remote_app"
    // permission_handler_android 14.x compiles against SDK 37.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.quickremote.quick_remote_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
