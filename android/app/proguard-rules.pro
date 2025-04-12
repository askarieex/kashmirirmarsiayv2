# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.platform.** { *; }

# Keep Flutter engine
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Keep R8 safe
-dontwarn io.flutter.embedding.**

# Keep Just Audio and related packages
-keep class com.google.android.exoplayer.** { *; }
-keep interface com.google.android.exoplayer.** { *; }
-keep class com.jaredrummler.android.device.** { *; }
-keep class io.just.** { *; }
-keep class kotlin.** { *; }
-keep class com.ryanheise.** { *; } 