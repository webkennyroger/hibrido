plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hibrido"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Este é o bloco de configuração CORRETO e ÚNICO.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hibrido"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Adicionado para resolver o erro "No matching variant" do spotify_sdk.
        // Instrui o Gradle a usar a dimensão 'default' quando nenhuma for encontrada.
        missingDimensionStrategy("default", "default")

        manifestPlaceholders += mapOf(
            "redirectSchemeName" to "hibrido",
            "redirectHostName" to "callback"
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // Adicionado para resolver o erro "No matching variant" do spotify_sdk.
            // Permite que a build de 'debug' use a versão 'release' de uma dependência se a de 'debug' não for encontrada.
            matchingFallbacks += "release"
        }
    }
}

dependencies {
    // Adiciona a dependência explícita para o módulo do Spotify SDK
    implementation(project(":spotify-app-remote"))
}

flutter {
    source = "../.."
}