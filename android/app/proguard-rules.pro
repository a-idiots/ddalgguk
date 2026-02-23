## Gson rules for flutter_local_notifications
## https://github.com/google/gson/blob/main/examples/android-proguard-example/proguard.cfg

# Gson uses generic type information stored in a class file when working with fields.
# R8 removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# Gson specific classes
-keep class com.google.gson.** { *; }

# Keep TypeToken and its subclasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic signatures of TypeToken and its subclasses
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
