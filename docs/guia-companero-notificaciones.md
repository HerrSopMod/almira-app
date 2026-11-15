# Avisos de vencimiento: dos alternativas

Contexto: el portfolio de Meta «Almira» quedó **restringido** (10 nov. 2026, «integridad de la cuenta») y mientras siga así WhatsApp no envía nada (error 131031). La parte de código, la base y las funciones de WhatsApp ya están en `main` y probadas; no hay que tocarlas. Hay dos caminos, que se pueden hacer a la vez.

| | A. WhatsApp con otra cuenta de Meta | B. Notificaciones en el teléfono |
|---|---|---|
| Depende de Meta | Sí | No |
| Llega con la app cerrada | Sí | Sí, si se programó antes |
| Código nuevo | Ninguno | Sí, en Flutter |
| Quién lo hace | Quien tenga una cuenta de Facebook limpia | Quien programe en Flutter |

---

## A. WhatsApp con la cuenta de Meta de otra persona

Cualquiera con una cuenta de Facebook **antigua y con uso normal** puede hacerlo. No cambia el código: solo se cambian los datos de Meta y los secretos de Supabase.

### Cómo evitar otra restricción
- Hazlo **a mano y con calma**, desde un solo navegador y sin VPN. Nada de extensiones que automaticen la página.
- Usa tus **datos reales** (nombre, correo). Nada falso.
- Activa antes la **autenticación en dos pasos** y una **passkey** en tu cuenta (Centro de cuentas > Contraseña y seguridad).
- Crea **un solo** portfolio y **una sola** app. No repitas pasos ni crees varias cuentas.
- Si Meta restringe algo, pide la **revisión** enseguida y explica la verdad: proyecto universitario, configuración manual.

### Pasos (los detalles de cada pantalla están en `docs/whatsapp-configuracion.md`)
1. Crea el portfolio en <https://business.facebook.com> y una app de tipo **Empresa** en <https://developers.facebook.com>. Agrega el producto **WhatsApp**.
2. En **Casos de uso > Personalizar > Paso 1. Probar**: anota el **Phone Number ID** y agrega los celulares que recibirán mensajes (máximo 5, cada uno se verifica con un código).
3. Copia la **Clave secreta de la aplicación** (Configuración de la aplicación > Información básica).
4. Genera el **token de acceso**: el temporal de «Paso 1. Probar» (dura 24 horas) o, mejor, uno permanente de un usuario del sistema (caducidad «Nunca»; permisos `whatsapp_business_messaging` y `whatsapp_business_management`).
5. En el Administrador de WhatsApp, crea las **cinco plantillas** de `docs/whatsapp-plantillas.md`, con esos nombres exactos, categoría Utility y los ejemplos de las variables. Espera a que estén **Activas**.
6. **Webhook** (Paso 2 > Configurar Webhooks):
   - URL: `https://hkzmamwtnqwytakemfqx.supabase.co/functions/v1/whatsapp-webhook`
   - Token de verificación: te lo da la dueña del proyecto de Supabase (ver paso 8).
   - Suscribirse al campo **`messages`**.
7. Pasa a la dueña del proyecto, por un canal **privado** (mensaje directo, nunca el repositorio ni un grupo): el Phone Number ID, el token de acceso y la clave secreta de la app.
8. **Quien administra Supabase** (el compañero no tiene acceso al panel) ejecuta, en PowerShell en la raíz del repo:

```powershell
# 1) Token de verificación nuevo: se guarda en Supabase y queda en el portapapeles para pegarlo en Meta.
$t = -join ((48..57)+(97..122) | Get-Random -Count 30 | % {[char]$_}); supabase secrets set WA_VERIFY_TOKEN=$t; Set-Clipboard $t

# 2) Con el token de acceso copiado:
supabase secrets set WA_ACCESS_TOKEN=$(Get-Clipboard)

# 3) Con la clave secreta de la app copiada:
supabase secrets set WA_APP_SECRET=$(Get-Clipboard)

# 4) El Phone Number ID (no es secreto):
supabase secrets set WA_PHONE_NUMBER_ID=NUMERO_DEL_PASO_2
```

   Hay que correr (2) y (3) uno a la vez, copiando cada valor antes. El token de verificación del paso (1) se pega en Meta con Ctrl+V.
9. **Probar:** en el APK, Mi perfil > Recordatorios por WhatsApp > celular permitido > Activar. Debe llegar la bienvenida. Si falla, el código de error queda en la tabla `recordatorios_enviados` (columna `error_resumen`): `190` es token vencido y `131031` es cuenta bloqueada.

Nota: la clave y los tokens **nunca** van en el repositorio ni en el chat.

---

## B. Notificaciones locales en la app (sin Meta ni Firebase)

La app lee las deudas de Supabase y **programa avisos en el teléfono**, con sonido y decoración propios. Salen con la app cerrada. Alcance: Android primero.

### Limitaciones que hay que conocer
- Solo conoce las deudas hasta la última vez que se abrió la app.
- Algunos teléfonos con ahorro de batería agresivo (Xiaomi, Oppo, Huawei) retrasan o cancelan alarmas.
- Android 13 o superior exige pedir el permiso de notificaciones.

### Qué construir
1. **Paquetes** (desde `apps/almira_flutter`): `flutter pub add flutter_local_notifications timezone flutter_timezone`.
2. **Android** (`android/app/build.gradle.kts` y `AndroidManifest.xml`):
   - Activar `coreLibraryDesugaring` (lo exige el paquete) y agregar `desugar_jdk_libs`.
   - Permisos: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` y, si quieres hora exacta, `SCHEDULE_EXACT_ALARM`. Si prefieres no pedir alarmas exactas, usa `AndroidScheduleMode.inexactAllowWhileIdle` (puede variar unos minutos).
   - Agregar los receptores `ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver` (la documentación del paquete trae el XML).
3. **Sonido propio:** coloca el audio en `android/app/src/main/res/raw/almira_aviso.ogg` (nombre en minúsculas, sin espacios; corto, de 1 a 2 segundos).
4. **Canal de notificación:** id `avisos_vencimiento`, importancia alta, sonido `RawResourceAndroidNotificationSound('almira_aviso')`, color de acento `0xFF0B7F86` (el turquesa de `app_colors.dart`). En Android 8 o superior el **sonido queda fijo al crear el canal**: para cambiarlo después hay que usar otro id de canal.
5. **Ícono de la barra:** debe ser monocromo (blanco sobre transparente). Android Studio > Image Asset > Notification Icon, con el logo de Almira, y se referencia como `@drawable/ic_notificacion`. El logo de color se puede usar como ícono grande.
6. **Servicio** `lib/features/notifications/servicio_notificaciones.dart`:
   - `inicializar()`: zona horaria, canal y toque de la notificación (que abra la deuda con `go_router`, por ejemplo `Rutas.deuda(id)`).
   - `pedirPermiso()`: solo al activar el interruptor, no al abrir la app.
   - `programar(List<Deuda> deudas, DateTime hoy)`: cancela lo anterior y, por cada deuda pendiente con saldo mayor a 0, agenda un aviso **3 días antes** y otro **el mismo día**, a las 10:00 hora local, solo si la fecha aún no pasó. Identificadores estables a partir del id de la deuda (por ejemplo, un hash más 0 o 1). Máximo unas 60 notificaciones.
   - `cancelarTodo()`: al cerrar sesión y al apagar el interruptor.
7. **Dónde llamarlo:** cuando `vistaProvider` cargue datos reales (no demostración), si el interruptor está activo. La fecha de hoy **siempre** con `relojProvider`, nunca una fecha fija.
8. **Interruptor:** en la pantalla **Avisos y canales** (ya existe en la app), «Avisos en este teléfono». Empieza apagado y pide el permiso al encenderlo. Sin texto de relleno: el título y nada más.
9. **Textos** (español de Perú, tú), con datos reales y sin nombre de municipalidad escrito en el código:
   - Título: «Tu impuesto predial vence en 3 días»; cuerpo: «Vence el 15 de noviembre. Pagarlo toma pocos pasos.»
   - El día mismo: «Hoy vence tu impuesto predial».
   - Usa los nombres de tributo que ya existen en `core/widgets/tributo.dart`. Monto con `soles()`. **Nunca** DNI ni cuponera.

### Pruebas y entrega
- **Prueba unitaria** de la función que calcula qué avisos agendar (fechas, deudas pagadas, deudas pasadas, sin duplicados). Es lógica pura, sin plugin.
- **Prueba de widget** del interruptor (apagado por defecto, pide permiso al encender).
- `flutter analyze` y `flutter test` deben pasar. Commits pequeños, en español, con formato `tipo(ámbito): descripción`.
- **En el teléfono:** para no esperar 3 días, programa de forma temporal un aviso a 1 minuto, comprueba sonido, ícono y apertura de la pantalla, y quita esa línea antes de hacer commit.
- Si Android no muestra el aviso: revisa el permiso de notificaciones, el ahorro de batería y que el canal tenga el sonido (los canales viejos no se actualizan: usa otro id).

### Lo que no hay que tocar
Las migraciones, las funciones de Supabase y los secretos de Meta: ya están hechos y desplegados.
