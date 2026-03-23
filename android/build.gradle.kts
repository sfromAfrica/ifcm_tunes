// android/build.gradle.kts (FINAL CORRECTED PROJECT-LEVEL FILE)

plugins {
    // 1. Android Application Plugin (Fixed to 8.11.1)
    id("com.android.application") version "8.11.1" apply false 
    
    // 2. Kotlin Android Plugin (Fixed to 2.2.20)
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false 
    
    // 3. Google Services Plugin (Fixed to 4.3.10)
    id("com.google.gms.google-services") version "4.3.10" apply false 
    
    // 4. Flutter Gradle Plugin: REMOVE THE VERSION TO AVOID CONFLICT
    // This allows Gradle to use the version provided by the Flutter SDK setup.
    id("dev.flutter.flutter-gradle-plugin") apply false // <--- FINAL CORRECTION
}

// ----------------------------------------------------------------------
// Configuration blocks
// ----------------------------------------------------------------------

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}