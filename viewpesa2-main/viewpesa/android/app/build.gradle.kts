plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.viewpesa"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Corrected property for desugaring
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.viewpesa"
        minSdk = 23
        //noinspection OldTargetApi
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true // Required for minSdk 21 with desugaring
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5") // Required for desugaring
    implementation("androidx.multidex:multidex:2.0.1") // Required for multiDex
}

flutter {
    source = "../.."
}