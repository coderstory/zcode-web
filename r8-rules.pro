# ZCode Web R8 规则
# 入口 Activity：清单引用，整类保留（含匿名内部类被引用者自动保留）
-keep class ai.zcode.web.MainActivity { public *; }

# ZXing 无反射调用，可达即保留；仅需压制无关警告
-dontwarn java.awt.**
-dontwarn javax.**
-dontwarn java.lang.invoke.**
-dontwarn com.google.zxing.**

# 保留行号便于崩溃定位（关掉体积更小，出问题再关）
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
