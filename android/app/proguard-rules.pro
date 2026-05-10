# Flutter ProGuard Rules

# Keep generic signatures and annotations
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson rules
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory

# Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.** { *; }

# Models
-keep class com.medtime.medtime.core.models.** { *; }

# Timezone
-keep class dev.flutter_community.plus.timezone.** { *; }
