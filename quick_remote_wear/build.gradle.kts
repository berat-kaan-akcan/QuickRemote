// Same toolchain as the phone app (quick_remote_app/android): upgrade both together.
plugins {
    id("com.android.application") version "9.1.0" apply false
    // AGP 9 compiles Kotlin itself (built-in Kotlin) with the Kotlin Gradle
    // plugin on the build classpath. Declaring it here moves that from AGP's
    // 2.2.10 to 2.4.0, the version the Compose compiler plugin must match.
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.0" apply false
}
