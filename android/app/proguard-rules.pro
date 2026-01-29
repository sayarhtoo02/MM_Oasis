# Flutter wrapper - ESSENTIAL
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep the application class
-keep class com.example.munajat_e_maqbool_app.** { *; }

# Google Play Core classes for in-app updates
-keep class com.google.android.play.core.** { *; }

# Supabase/Realtime WebSocket
-keep class org.java_websocket.** { *; }
-keep class io.socket.** { *; }
-dontwarn org.java_websocket.**

# AndroidX Core
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep local_auth biometric classes
-keep class androidx.biometric.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepattributes RuntimeVisibleAnnotations
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# General Android keep rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
-keep public class * extends java.lang.Exception

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# OkHttp and Retrofit
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-dontwarn sun.misc.**

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Workmanager
-keep class androidx.work.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep R8 from removing BuildConfig
-keep class **.BuildConfig { *; }
-keep class **.R { *; }
-keep class **.R$* { *; }

# Video Player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# WebView Flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Vibration
-keep class com.github.nickneenan.vibration.** { *; }

# Audio Players
-keep class xyz.luan.audioplayers.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# OTA Update
-keep class io.github.nicholasqiu.ota_update.** { *; }

# Connectivity
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Device Info
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Package Info Plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Google Play Core - Deferred Components
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Suppress all warnings for libraries (safer for release)
-dontwarn **
