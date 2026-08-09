plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "jp.sentino.general"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 与 iOS bundle ID 及 AppConfig.packageName 保持一致
        applicationId = "jp.sentino.general"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        // debug 不加 applicationIdSuffix：目前 debug/release 同用 debug key 签名，
        // 同包名可直接覆盖安装，并存的收益不抵「每个包名各需一条 Android OAuth
        // client」的维护成本（漏一条的症状是「Google 登录失败而其余功能正常」）。
        // 等有了 release keystore（签名不同 → 同包名无法互相覆盖，切换要先卸载）
        // 再把 ".dev" 加回来，届时 Console 需相应补一条 client。
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
