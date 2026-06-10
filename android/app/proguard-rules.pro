# ── Generic-signature preservation ──
# Gson and other reflection-based libraries need generic type info at runtime
# (e.g. TypeToken<ArrayList<NotificationDetails>>). Without these attributes,
# R8 strips the parameter and you get `Missing type parameter` at runtime.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ── flutter_local_notifications ──
# Keep all plugin classes — they're reflected on by name and use Gson for
# scheduled-notification persistence.
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# ── Gson ──
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# ── Serialization ──
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * implements java.io.Serializable { *; }

# ── audio_service / just_audio / video_player (keep their bridges intact) ──
-keep class com.ryanheise.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ── Flutter standard ──
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Suppress noisy warnings from optional deps ──
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# ── Play Core / deferred components ──
# Flutter's embedding references com.google.android.play.core.* for deferred
# component installation. We don't use deferred components, so tell R8 not to
# fail when those classes aren't present.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
