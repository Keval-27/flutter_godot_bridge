plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_godot_bridge_example"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_godot_bridge_example"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ADD THIS CORRECTED BLOCK
        externalNativeBuild {
            cmake {
                arguments.add("-DANDROID_STL=c++_shared")
            }
        }
    }


    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    repositories {
        flatDir {
            dirs("libs")
        }
    }
    lint {
        checkReleaseBuilds = false
    }

    packagingOptions {
        jniLibs {
            pickFirsts.add("lib/arm64-v8a/libgodot_android.so")
            pickFirsts.add("lib/armeabi-v7a/libgodot_android.so")
            pickFirsts.add("lib/x86/libgodot_android.so")
            pickFirsts.add("lib/x86_64/libgodot_android.so")
        }
    }


}

flutter {
    source = "../.."
}
dependencies {
    // Add your Godot AAR
    implementation(files("libs/godot-lib-debug.aar"))

    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("androidx.core:core-ktx:1.12.0")
}
