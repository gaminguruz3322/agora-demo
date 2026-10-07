# Agora Chat / Hyphenate
-keep class com.hyphenate.** { *; }

# Agora SDK
-keep class io.agora.** { *; }

# Hyphenate Chat adapter classes
-keep class com.hyphenate.chat.adapter.** { *; }

# Native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Required metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Hyphenate optional vendor push SDKs
-dontwarn com.heytap.msp.push.**
-dontwarn com.meizu.cloud.pushsdk.**
-dontwarn com.vivo.push.**
-dontwarn com.xiaomi.mipush.**

# Agora Chat SDK
-keep class com.hyphenate.** {*;}
-dontwarn com.hyphenate.**

# Agora RTC SDK
-keep class io.agora.** {*;}
-dontwarn io.agora.**