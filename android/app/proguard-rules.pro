# Flutter ProGuard Rules

# Keep the plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the models if they are used in reflection (sqflite doesn't usually need this, but good for safety)
-keep class com.medtime.medtime.core.models.** { *; }

# timezone
-keep class dev.flutter_community.plus.timezone.** { *; }
