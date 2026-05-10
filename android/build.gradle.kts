import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.kumpali.video_thumbnail_plugin"
version = "1.0-SNAPSHOT"

repositories {
    google()
    mavenCentral()
}

android {
    namespace = "com.kumpali.video_thumbnail_plugin"
    compileSdk = 37

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_21)
        }
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }

        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    testOptions {
        unitTests.all {
            useJUnitPlatform()

            testLogging {
                events(
                    "passed",
                    "skipped",
                    "failed",
                    "standardOut",
                    "standardError"
                )

                showStandardStreams = true
            }

            outputs.upToDateWhen {
                false
            }
        }
    }
}

dependencies {
    implementation("com.github.bumptech.glide:gifencoder-integration:5.0.7")
    implementation("com.squareup.okhttp3:okhttp:5.3.2")

    testImplementation(kotlin("test"))
    testImplementation("org.mockito:mockito-core:5.23.0")
}