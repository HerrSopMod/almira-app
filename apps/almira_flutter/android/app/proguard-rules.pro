# Reglas propias del build release. El plugin de Flutter agrega este archivo
# a R8 automáticamente cuando existe.

# ML Kit (etiquetado de imágenes): clases que el modelo carga por reflexión.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google_mlkit_image_labeling.** { *; }
-keep class com.google_mlkit_commons.** { *; }
