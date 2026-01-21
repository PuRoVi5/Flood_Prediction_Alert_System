// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()       // already আছে
        mavenCentral() // already আছে
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath 'com.google.gms:google-services:4.3.15' // <-- Firebase জন্য
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// তোমার custom build directory code
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
