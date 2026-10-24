import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 출시 서명은 휴대폰 앱과 같은 업로드 키를 쓴다. 키 파일은 git에 올리지 않는다.
// 우선순위: wear_app/android/key.properties, 없으면 휴대폰 앱의 android/key.properties.
// 둘 다 없으면(내 시계 테스트 빌드) debug 키로 서명한다. storeFile은 key.properties가
// 있는 폴더 기준 경로로 읽는다.
val keystorePropertiesFile = listOf(
    rootProject.file("key.properties"),
    rootProject.file("../../android/key.properties"),
).firstOrNull { it.exists() }
val keystoreProperties = Properties()
if (keystorePropertiesFile != null) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.sharerun.share_run_challenge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sharerun.share_run_challenge"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Wear OS 3.0(API 30) 이상.
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile != null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // 휴대폰 앱의 android/app 기준 경로를 그대로 쓰는 key.properties도 읽는다.
                val storePath = keystoreProperties.getProperty("storeFile")
                storeFile = if (keystorePropertiesFile.parentFile == rootProject.projectDir) {
                    file(storePath)
                } else {
                    File(keystorePropertiesFile.parentFile, "app").resolve(storePath).normalize()
                }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
