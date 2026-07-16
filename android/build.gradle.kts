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
subprojects {
    project.evaluationDependsOn(":app")
}

// Flutter plugins (geolocator_android, image_picker_android, …) reference recent
// androidx APIs. Force recent androidx versions across EVERY module so the
// classes resolve at compile time regardless of what each plugin declares.
subprojects {
    configurations.all {
        resolutionStrategy {
            force(
                "androidx.core:core:1.13.1",
                "androidx.core:core-ktx:1.13.1",
                "androidx.activity:activity:1.9.3",
                "androidx.activity:activity-ktx:1.9.3",
                "androidx.fragment:fragment:1.8.5",
                "androidx.exifinterface:exifinterface:1.3.7",
                "androidx.annotation:annotation:1.9.1",
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
