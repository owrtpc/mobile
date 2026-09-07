import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesPath = providers.environmentVariable("OWRTPC_ANDROID_SIGNING_PROPERTIES").orNull
val releaseSigning = Properties()
val signingPropertiesFile = signingPropertiesPath?.let { file(it) }
if (signingPropertiesFile != null) {
    require(signingPropertiesFile.isFile) { "Android release signing properties are unavailable" }
    signingPropertiesFile.inputStream().use { releaseSigning.load(it) }
    for (key in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        require(!releaseSigning.getProperty(key).isNullOrBlank()) { "Android release signing property missing: $key" }
    }
}
gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release") }) {
        check(signingPropertiesFile != null) {
            "Release signing is required. Set OWRTPC_ANDROID_SIGNING_PROPERTIES; debug signing is never used for release."
        }
    }
}

android {
    namespace = "org.owrtpc.mobile"
    compileSdk = 37
    compileSdkMinor = 0
    buildToolsVersion = "36.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.owrtpc.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingPropertiesFile != null) {
            create("production") {
                storeFile = signingPropertiesFile.parentFile.resolve(releaseSigning.getProperty("storeFile"))
                storePassword = releaseSigning.getProperty("storePassword")
                keyAlias = releaseSigning.getProperty("keyAlias")
                keyPassword = releaseSigning.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("production")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
