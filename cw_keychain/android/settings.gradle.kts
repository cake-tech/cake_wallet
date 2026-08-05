pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Plugin versions live here, not in build.gradle.kts. This file is only used when
    // android/ is opened on its own (IDE sync, ./gradlew here). When the plugin is built
    // as a subproject of the host app, Flutter includes it via the app's settings.gradle
    // and this file is ignored -- AGP and the Kotlin plugin are already on the classpath
    // there, and requesting them *with* a version is a hard error. Keeping the versions
    // here lets build.gradle.kts stay versionless and work in both contexts.
    plugins {
        id("com.android.library") version "8.9.1"
        id("org.jetbrains.kotlin.android") version "2.3.20"
    }
}

rootProject.name = "cw_keychain"
