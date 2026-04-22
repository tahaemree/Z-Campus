# Keep Flutter entry points and required JNI bridges.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase runtime classes used by reflection.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Gson model metadata when reflection is used.
-keepattributes Signature
-keepattributes *Annotation*

# Suppress missing Google Play Core classes (used by Flutter deferred components).
-dontwarn com.google.android.play.core.**

