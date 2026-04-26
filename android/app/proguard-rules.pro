# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Play Core (Deferred Components)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ─────────────────────────────────────────────────────────────────────────────
# Meta (Facebook) SDK — App Events & Ads Attribution
# ─────────────────────────────────────────────────────────────────────────────
# Keep all Facebook SDK classes (required for ads attribution & event tracking)
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# Keep Bolts (Facebook's internal async task library)
-keep class bolts.** { *; }
-dontwarn bolts.**

# Keep Facebook's JNI / native bridge
-keepclassmembers class * {
    @com.facebook.common.internal.DoNotStrip *;
}

# Preserve Facebook AppEventsLogger internal reflection calls
-keepnames class com.facebook.appevents.** { *; }

