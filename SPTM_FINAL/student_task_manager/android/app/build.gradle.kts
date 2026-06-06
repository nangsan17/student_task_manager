plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.2"
}
 
android {
    namespace = "com.example.sptm"
    compileSdk = 36
    ndkVersion = "28.2.13676358"  
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  
    }
    
 
    kotlinOptions {
        jvmTarget = "11"
    }
 
    defaultConfig {
        applicationId = "com.example.sptm"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode?.toInt() ?: 1
        versionName = flutter.versionName ?: "1.0"
    }
 
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
 
flutter {
    source = "../.."
}
 
dependencies {
    implementation("com.google.firebase:firebase-messaging:23.2.1")
    implementation("com.google.firebase:firebase-analytics:21.3.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")  // ← ADD THIS
}