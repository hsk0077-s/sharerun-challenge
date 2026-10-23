import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// 구글 플레이에 올리는 업로드 키. android/key.properties 가 있으면 그 키로 서명하고,
// 없으면(내 폰 테스트 빌드) 예전처럼 디버그 키로 서명한다. 이 파일과 키 파일은 git에 올리지 않는다.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// 네이버 로그인 SDK는 매니페스트의 client id / secret 을 읽는다. 값은 git에 두지 않는다.
// 우선순위: --dart-define-from-file 이 넘긴 값, android/naver.properties, 프로젝트 .env.
fun decodeDartDefines(): Map<String, String> {
    val raw = (project.findProperty("dart-defines") as? String).orEmpty()
    if (raw.isBlank()) return emptyMap()
    val out = linkedMapOf<String, String>()
    for (entry in raw.split(",")) {
        if (entry.isBlank()) continue
        val decoded = try {
            String(Base64.getDecoder().decode(entry), Charsets.UTF_8)
        } catch (_: IllegalArgumentException) {
            entry
        }
        val separator = decoded.indexOf('=')
        if (separator <= 0) continue
        out[decoded.substring(0, separator)] = decoded.substring(separator + 1)
    }
    return out
}

fun parseEnvFile(envFile: java.io.File): Map<String, String> {
    if (!envFile.isFile) return emptyMap()
    val out = linkedMapOf<String, String>()
    envFile.readLines(Charsets.UTF_8).forEach { rawLine ->
        val line = rawLine.trim()
        if (line.isEmpty() || line.startsWith("#")) return@forEach
        val separator = line.indexOf('=')
        if (separator <= 0) return@forEach
        val key = line.substring(0, separator).trim()
        var value = line.substring(separator + 1).trim()
        if (value.length >= 2 &&
            ((value.startsWith("\"") && value.endsWith("\"")) ||
                (value.startsWith("'") && value.endsWith("'")))
        ) {
            value = value.substring(1, value.length - 1)
        }
        out[key] = value
    }
    return out
}

fun xmlAttr(value: String): String = value
    .replace("&", "&amp;")
    .replace("\"", "&quot;")
    .replace("'", "&apos;")
    .replace("<", "&lt;")

val dartDefines = decodeDartDefines()
val naverPropertiesFile = rootProject.file("naver.properties")
val naverProperties = Properties()
if (naverPropertiesFile.exists()) {
    FileInputStream(naverPropertiesFile).use { naverProperties.load(it) }
}
val dotenvValues = parseEnvFile(rootProject.file("../.env"))

fun naverCredential(key: String): String {
    val fromDefine = dartDefines[key]?.trim().orEmpty()
    if (fromDefine.isNotEmpty()) return fromDefine
    val fromProperties = naverProperties.getProperty(key)?.trim().orEmpty()
    if (fromProperties.isNotEmpty()) return fromProperties
    return dotenvValues[key]?.trim().orEmpty()
}

android {
    namespace = "com.sharerun.share_run_challenge"
    // Health Connect (health package): compileSdk >= 34, minSdk >= 26.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sharerun.share_run_challenge"
        // Health Connect minimum SDK.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["naverClientId"] = xmlAttr(naverCredential("NAVER_CLIENT_ID"))
        manifestPlaceholders["naverClientSecret"] = xmlAttr(naverCredential("NAVER_CLIENT_SECRET"))
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 릴리스의 코드 최적화(R8)가 네이버 로그인 SDK를 지우지 않게 하는 규칙.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// 구글 플레이에 올리는 파일(AAB)을 만들 때 업로드 키가 없으면 디버그 키로 몰래 서명하지 않고 멈춘다.
// (내 폰 시험용 flutter run / build apk 는 bundleRelease 를 쓰지 않으므로 영향이 없다.)
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name == "bundleRelease" }) {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "업로드 키가 없습니다. android/key.properties 를 만든 뒤 다시 빌드하세요. (docs/play-release.md)",
            )
        }
        // 이 파일이 없으면 빌드는 성공하지만 Firebase 설정이 빠져 앱이 시작되지 못할 수 있다.
        if (!file("google-services.json").exists()) {
            throw GradleException(
                "android/app/google-services.json 이 없습니다. Firebase 콘솔에서 받아 android/app 에 둔 뒤 다시 빌드하세요. (docs/play-release.md)",
            )
        }
        val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missing = required.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "android/key.properties 에 빠진 항목이 있습니다: " + missing.joinToString(", "),
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
    // Play Integrity: device/app verdict, recorded by the server only.
    implementation("com.google.android.play:integrity:1.4.0")
}
