# Almira · app de vecinos (Flutter)

Cliente móvil de Almira en Flutter y Dart. Reemplaza a la app de Expo (`apps/mobile`), que queda en el repo como referencia. Usa el mismo backend de Supabase; las migraciones `20261111000001_estado_de_cuenta.sql` y la función `registro-contribuyente` agregan el estado de cuenta, el pago y el registro por cuponera.

## Ejecutar

Requiere Flutter estable (probado con 3.47.9), JDK 17 y el SDK de Android.

```bash
cd apps/almira_flutter
flutter pub get
flutter run                                        # modo demostración
flutter run --dart-define-from-file=env.json       # con Supabase
```

Para conectar el backend, copia `env.example.json` como `env.json` y completa:

| Variable | Valor |
| --- | --- |
| `SUPABASE_URL` | URL del proyecto (Project Settings → API) |
| `SUPABASE_ANON_KEY` | Clave anon, la pública. Nunca la `service_role` |

`env.json` está fuera de git. Sin esas variables la app abre en **modo demostración**.

## Compilar la APK

```bash
flutter build apk --release                                    # demostración
flutter build apk --release --dart-define-from-file=env.json   # con Supabase
```

Sale en `build/app/outputs/flutter-apk/app-release.apk`. Se instala con `adb install` o copiándola al teléfono.

La compilación `release` se firma con la clave de depuración de Android: sirve para instalar y probar, **no para publicar** en Google Play. Para publicar hace falta una clave propia en `android/app/build.gradle.kts`.

## Backend

Supabase, el mismo que usa el repo (`supabase/migrations`):

- **Auth:** Google (Supabase Auth, con regreso por `almira://ingreso`) como método principal, y correo o número de cuponera con la clave web como alternativa. El **número de cuponera** es un dato privado (columna `vecinos.numero_cuponera`), distinto del **código de contribuyente** (el del estado de cuenta, con el que se entra después junto a la clave web). Con Google, la cuenta nueva vincula su cuponera: municipalidad, número de cuponera y DNI, y puede crear su clave web en ese momento (función `vincular_contribuyente`, con límite de intentos y un mismo mensaje ante cualquier fallo), verifica su celular y acepta el consentimiento. Quien ya está vinculado entra directo. También se puede registrar con correo (Edge Function `registro-contribuyente`, que nunca expone la tabla de contribuyentes). La clave web se crea después desde Mi perfil. La sesión se guarda cifrada (`flutter_secure_storage`). Lo elegido en el ingreso va en `user_metadata.almira`.
- **Datos:** lee `municipalidades`, `vecinos`, `predios`, `deudas`, `pagos`, `recordatorios`, `reclamos` y `obras`. Las políticas RLS dejan pasar solo las filas del vecino.
- **Reclamos:** la foto sube al bucket privado `evidencias`, en `{municipalidad}/{usuario}/{archivo}`, y el reclamo se inserta con las columnas que el vecino puede escribir. En el seguimiento la foto se lee con una URL firmada de una hora.
- **Código de contribuyente:** función `vincular_contribuyente` (códigos adicionales desde Mi perfil).
- **Estado de cuenta y cuponera:** `deudas` guarda un periodo por fila (tributo, año, trimestre, insoluto, gastos, intereses, descuento, pagos, saldo, nro. de valor y expediente coactivo). Los PDF (estado de cuenta, HR, HLP y HLA) se generan en el teléfono (`pdf`, `printing`).
- **Pago en línea (3 pasos):** Deuda → Medio de pago (tarjeta o Yape) → Comprobante en PDF. Los datos de la tarjeta o de Yape solo se comprueban en el teléfono: no se guardan ni se registran, y al servidor viajan únicamente las deudas y el medio. La función `registrar_pago` confirma el pago en el servidor: toma el saldo de la base, registra el pago y marca la deuda como pagada. El cobro pasa por la interfaz `PaymentGateway` (`payment_gateway.dart`): hoy la implementa `PasarelaServidor`, y `PasarelaMunicipal` es el lugar para la pasarela real de la municipalidad. La pantalla se actualiza sola por Realtime.
- **Datos de prueba:** `supabase/seed-contribuyentes.sql` (idempotente) carga los cinco contribuyentes.
- **Canal de avisos:** actualiza `vecinos.canal_preferido`.

## Qué funciona, qué es demostración y qué falta

| Función | Con Supabase | Modo demostración |
| --- | --- | --- |
| Ingreso | Correo o cuponera, y registro con cuponera | Un botón, sin cuentas |
| Inicio, Pagar, Obras | Datos de la base | Registros de ejemplo, con la etiqueta «Demostración» |
| Pago en línea | Pestañas por tributo, medio de pago y confirmación en el servidor | No disponible, y lo dice |
| Nuevo reclamo | Sube la foto y guarda en la base. La foto es obligatoria (lo exige la tabla) | Se guarda en el teléfono, con foto y ubicación. La foto es opcional |
| Seguimiento | Foto desde Storage, mapa y plazo calculado | Igual, desde el teléfono |
| Asistente | Chat tipo mensajería con la función `asistente` de Supabase (Gemini), que lee solo los datos del propio vecino y recibe los totales ya calculados, sin DNI ni cuponera. Ver `supabase/functions/asistente/README.md` | Reglas fijas sobre los datos de la app |
| Avisos | Lista los recordatorios recibidos y cambia el canal preferido | Igual, en el teléfono |
| Atención | Muestra el teléfono de ayuda si la municipalidad lo publicó | Igual |

Los datos de demostración salen de `packages/shared/src/datos-ejemplo.ts` y viven en `lib/shared/services/datos_demo.dart`. Sus fechas se calculan desde hoy.

Pendiente o fuera de alcance:

- **Pasarela real de cobro:** el pago se registra en el servidor, pero no se conecta con un banco ni con Yape/Plin.
- **Verificación del celular y de Yape:** el código de 6 dígitos no se envía por SMS (no hay proveedor contratado) y el de aprobación de Yape tampoco se valida con Yape: las pantallas aceptan cualquier código de 6 dígitos.
- **Simulación de cuotas y chat con una persona:** eran simulados en la app anterior y no se migraron.
- **Buscar una dirección en el mapa:** el pin se ubica moviendo el mapa o con el GPS.
- **Textos legales de privacidad:** son informativos. Falta validarlos con la asesoría legal de la municipalidad (Ley N.° 29733).
- **Reclamos antiguos con títulos de prueba** (por ejemplo, «Jjkkk»): la app ya no deja crearlos, pero los que están en la base hay que corregirlos allí.

## Mapa

OpenStreetMap con `flutter_map`, sin clave. Un solo componente (`lib/core/widgets/mapa_almira.dart`) sirve a Obras, Nuevo reclamo y Seguimiento. Muestra siempre la atribución y, si las teselas fallan, «No se pudo cargar el mapa» con «Reintentar».

Las teselas públicas de OpenStreetMap son para uso ligero. Una app con mucho tráfico necesita un proveedor con contrato: cambia `ConfigMapa.teselas`.

La base no guarda el centro de cada distrito. El mapa se centra en el promedio de las obras ubicadas; sin obras, muestra Lima.

## Errores corregidos

| Antes | Ahora |
| --- | --- |
| «Quedan 16 de 10 días» | El plazo se calcula con la fecha real. Si los datos no cuadran, «Plazo por confirmar» |
| La foto del reclamo era un dibujo fijo | Se sube, se guarda y se muestra la foto real, con carga, error y reintento |
| Reclamos sin mapa | Selector de ubicación con pin y mapa en el seguimiento |
| Franja del reloj en blanco | Encabezado turquesa detrás de la barra del sistema, con íconos claros |
| Cinco pasos antes de entrar | Dos, una sola vez |
| WhatsApp y asistente activados de fábrica | Todo lo opcional empieza apagado |
| Montos y fechas con una fecha fija de ejemplo | Fecha del teléfono |
| Títulos como «Jjkkk» | El asunto se valida |

El detalle por pantalla está en `CHANGELOG.md`.

## Pruebas

```bash
flutter analyze
flutter test
flutter test integration_test/flujo_demo_test.dart -d <dispositivo>
```

Ver el estado de cada una en `CHANGELOG.md` → «Pruebas ejecutadas».

## Estructura

```text
lib/
  app/          tema, rutas y arranque
  core/         configuración, errores, utilidades y componentes comunes
  features/     auth, onboarding, home, payments, complaints, public_works,
                assistant, profile, notifications, shell
  shared/       modelos y acceso a datos (Supabase y demostración)
```

Estado con Riverpod, rutas con `go_router`, tema Material 3 centralizado en `lib/app/theme`.
