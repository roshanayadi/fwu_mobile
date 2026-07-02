# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# For http/mailer if they use reflection
-keep class com.sun.mail.** { *; }
-keep class javax.mail.** { *; }

# Play Store deferred components — not used but referenced by Flutter engine
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Prevent obfuscation of specific data models if accessed via native side
-keep class np.edu.fwu.fwu_mobile.models.** { *; }

# Flutter handles most of its own obfuscation, but R8 can sometimes
# interfere with plugins that use reflection or method names as strings.
-keepattributes Signature,Annotation,Exceptions
