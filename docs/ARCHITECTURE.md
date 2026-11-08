# Arquitectura de Almira

Almira permite a vecinos de distintas municipalidades de Lima pagar tributos y reclamar con evidencia. Almira es la marca fija; la municipalidad es un dato que el vecino elige.

**Estado actual:** esqueleto con datos de ejemplo. Las apps todavía no se conectan a Supabase: no hay autenticación real, pasarela de pago, captura de fotos ni envío real de avisos.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `apps/mobile` | App de vecinos con Expo, React Native, TypeScript y expo-router |
| `apps/web` | Panel municipal con Vite, React y TypeScript |
| `packages/shared` | Tokens de diseño, tipos, formato y datos de ejemplo |
| `supabase` | Migraciones, RLS, datos de semilla y Edge Function |
| `docs/design` | Diseños de Stitch y `DESIGN.md`, solo como referencia |

Las apps importan `@almira/shared` directamente desde su código TypeScript, sin paso de compilación.

## Rutas móviles

| Pantalla | Ruta | Archivo |
| --- | --- | --- |
| Entrada (01) | `/entrada` | `app/(auth)/entrada.tsx` |
| Ingresa a tu cuenta (02) | `/ingreso` | `app/(auth)/ingreso.tsx` |
| Tus datos, tus reglas (03) | `/consentimiento` | `app/(auth)/consentimiento.tsx` |
| Sin smartphone (23) | `/sin-smartphone` | `app/sin-smartphone.tsx` |
| Privacidad y mis datos (22) | `/privacidad` | `app/privacidad.tsx` |
| Inicio (04) | `/inicio` | `app/(tabs)/inicio/index.tsx` |
| Recordatorios (09) | `/inicio/recordatorios` | `app/(tabs)/inicio/recordatorios.tsx` |
| Mi perfil (21) | `/inicio/perfil` | `app/(tabs)/inicio/perfil.tsx` |
| Detalle del aviso (10) | `/avisos/[id]` | `app/avisos/[id].tsx` |
| Cómo llegan los avisos (11) | `/avisos/como-llegan` | `app/avisos/como-llegan.tsx` |
| Atención humana (14) | `/atencion-humana` | `app/atencion-humana.tsx` |
| Mi cuenta municipal (05) | `/cuenta` | `app/(tabs)/cuenta/index.tsx` |
| Detalle de la deuda (06) | `/cuenta/deuda/[id]` | `app/(tabs)/cuenta/deuda/[id].tsx` |
| Confirma tu pago (07) | `/pago/confirmar` | `app/pago/confirmar.tsx` |
| Constancia de pago (08) | `/pago/constancia` | `app/pago/constancia.tsx` |
| Asistente con IA (12) | `/asistente` | `app/(tabs)/asistente.tsx` |
| Simulación de cuotas (13) | `/simulacion-cuotas` | `app/simulacion-cuotas.tsx` |
| Reclamos (15) | `/reclamos` | `app/(tabs)/reclamos/index.tsx` |
| Seguimiento (18) | `/reclamos/[id]` | `app/(tabs)/reclamos/[id].tsx` |
| Nuevo reclamo (16) | `/reclamo/nuevo` | `app/reclamo/nuevo.tsx` |
| Envío al área (17) | `/reclamo/envio` | `app/reclamo/envio.tsx` |
| Mapa de obras (19) | `/obras` | `app/(tabs)/obras/index.tsx` |
| Detalle de la obra (20) | `/obras/[id]` | `app/(tabs)/obras/[id].tsx` |

Flujo de entrada:

- Entrada (se elige la municipalidad), ingresa a tu cuenta, tus datos tus reglas, inicio.
- Desde la entrada, "No tengo cuenta ni smartphone propio" lleva a sin smartphone.

El ingreso es simulado: los campos vienen llenos con los datos de ejemplo y cualquier código de 6 dígitos sirve. No se envía ningún SMS.

`src/sesion.tsx` guarda la municipalidad elegida en memoria y filtra todos los datos por ella.

Las pestañas son Inicio, Mi cuenta, Asistente, Reclamos y Obras. El pago es simulado: al confirmar, `registrarPagoSimulado` crea pagos en memoria con estado `pendiente` (solo el servidor confirma pagos), las deudas se ven como pagadas hasta cerrar la app y se abre la constancia con un QR dibujado, que no codifica nada. Los plazos, vencimientos y fechas de pago usan `HOY_EJEMPLO` (1 nov 2026) en vez de la fecha del teléfono.

El asistente no usa IA: `responderAsistente` (`packages/shared/src/asistente.ts`) responde con textos fijos si la pregunta menciona cuotas o la multa, y con un mensaje que orienta a las preguntas sugeridas o a hablar con una persona en cualquier otro caso. La conversación vive solo en la pantalla. La simulación de cuotas usa las deudas pendientes (o solo las vencidas) y la tasa ilustrativa del prototipo (1 % mensual, cuota fija); es informativa y "Pedir evaluación a Rentas" no envía nada. Atención humana es simulada: el tiempo de espera es de ejemplo y no hay nadie conectado; solo promete compartir la consulta con el asistente si el vecino lo autorizó en el consentimiento.

Reclamos: la foto y la ubicación son simuladas (no se usa la cámara ni el GPS). "Agregar foto" solo marca que hay una foto de ejemplo y las pantallas 17 y 18 muestran un dibujo fijo según la categoría (`FotoSimulada`). La ubicación parte de la dirección del predio y el vecino puede ajustarla a mano. `clasificarReclamo` (`packages/shared/src/reclamos.ts`) elige la categoría con palabras clave y `AREA_TIPO_RECLAMO` da el área; no hay IA. El plazo de ejemplo es de 10 días hábiles para todas las categorías. Al confirmar, `registrarReclamo` guarda el reclamo en memoria con el siguiente código de la municipalidad, estado `derivado` y fecha `HOY_EJEMPLO`, y abre su seguimiento. El estado lo cambia la municipalidad.

Obras: el mapa es un dibujo fijo (`MapaObras`), no un mapa real; los marcadores se ubican en puestos fijos según el orden de las obras, porque las obras no tienen coordenadas. El detalle muestra una imagen ilustrativa porque no hay fotos publicadas.

Mi perfil vive dentro de la pestaña Inicio. "Texto más grande" (`src/textoGrande.tsx`) agranda en memoria todos los textos de `Texto`. Cerrar sesión vuelve a la entrada. Privacidad y mis datos muestra y cambia los permisos que guardó el consentimiento; las solicitudes ARCO son simuladas. Sin smartphone usa un número SMS y un horario de ejemplo (`SMS_NUMERO_EJEMPLO`, `HORARIO_MODULO_EJEMPLO`) y la reserva de turno es simulada.

Recordatorios vive dentro de la pestaña Inicio; el detalle del aviso y "Cómo llegan los avisos" se abren encima de las pestañas. Los títulos y mensajes de los avisos salen de `packages/shared/src/avisos.ts` con los datos de la deuda y el `nombreCorto` de la obra (si la obra no lo tiene, el mensaje no la menciona). El canal elegido en "¿Por dónde te avisamos?" se guarda en memoria por municipalidad y empieza con el canal preferido del vecino. Los mensajes de la pantalla 11 son ejemplos: no se envía nada.

## Panel web

| Página | Ruta | Archivo |
| --- | --- | --- |
| Ingreso (web-01) | `/ingreso` | `src/paginas/Ingreso.tsx` |
| Panel municipal (web-02) | `/panel` | `src/paginas/PanelMunicipal.tsx` |
| Recaudación y pagos (web-03) | `/recaudacion` | `src/paginas/Recaudacion.tsx` |
| Avisos y respuestas (web-04) | `/avisos` | `src/paginas/Avisos.tsx` |
| Reclamos por área (web-05) | `/reclamos` | `src/paginas/Reclamos.tsx` |
| Obras publicadas (web-06) | `/obras` | `src/paginas/Obras.tsx` |
| Atención humana (web-07) | `/atencion` | `src/paginas/AtencionHumana.tsx` |
| Alertas y auditoría (web-08) | `/alertas` | `src/paginas/Alertas.tsx` |
| Datos y accesos (web-09) | `/datos` | `src/paginas/DatosAccesos.tsx` |

El ingreso es simulado: no hay autenticación real y cualquier usuario y contraseña entran. Solo se ofrecen las municipalidades que tienen cifras de ejemplo para el panel (hoy, solo Lince); si hubiera más, aparece un selector. El pie de la barra lateral muestra el rol de ejemplo (`PERSONAL_PANEL_EJEMPLO`).

Las cifras agregadas (recaudación, pagos a tiempo, gráficos, casos de atención humana, alertas) son de ejemplo, iguales a las del prototipo, y viven en `packages/shared/src/panel-ejemplo.ts`, separadas de los datos de vecinos. Los reclamos y las obras salen de `datos-ejemplo.ts`, filtrados por la municipalidad.

`src/estado.tsx` guarda la sesión y una copia en memoria de los reclamos, obras y casos de la municipalidad. Las cifras de la barra lateral y "Requiere tu decisión" se calculan con esa copia. Nada se guarda: al recargar, el panel vuelve al ingreso y a los datos de ejemplo.

Recaudación y Avisos solo muestran cifras agregadas, sin nombres ni rankings de vecinos. Las acciones cambian solo la copia en memoria y lo avisan en pantalla: "Usar variante B" marca la variante elegida sin cambiar ningún envío; "Responder y cerrar" deja el reclamo resuelto sin guardar nada ni avisar al vecino; "Corregir área" cambia el área; en Obras se puede publicar o despublicar, sumar 5 % de avance (la obra queda actualizada hoy) y agregar una obra nueva, que entra sin publicar. En Atención humana, "Tomar" pasa el caso a "En atención"; en Alertas, el interruptor del simulador de cuotas solo cambia en el panel. La app del vecino no se entera de ninguno de estos cambios. Los casos, alertas, umbrales, auditorías, registro de accesos y solicitudes ARCO son de ejemplo, y esas páginas lo dicen al pie. La clasificación del reclamo se muestra sin porcentaje de confianza, porque sale de reglas fijas. La zona de cada reclamo de ejemplo está en `zonaReclamo` del panel, porque la tabla `reclamos` no tiene zona.

`src/estilos.css` solo usa variables CSS que `src/tema.ts` crea con los tokens de `@almira/shared` (`panelSizes` y `panelTypography` para las medidas y textos del panel). Los gráficos son HTML y CSS, sin librerías.

## Modelo de datos

Cada tabla de datos lleva `municipalidad_id`.

- `vecinos` tiene una fila por persona y municipalidad: quien tributa en dos distritos tiene dos filas. `user_id` queda vacío hasta que vincula su DNI.
- Las llaves foráneas compuestas `(municipalidad_id, id)` impiden que una deuda, un pago o un reclamo apunte a un vecino de otra municipalidad, incluso con `service_role`.
- `reclamos.foto_ruta` es obligatoria y debe estar en la carpeta de su municipalidad.

## Seguridad

Las funciones de `supabase/migrations/20261031000002_rls.sql` viven en el esquema `privado`, que PostgREST no expone.

| Tabla | Vecino | Personal de la municipalidad | Solo `service_role` |
| --- | --- | --- | --- |
| `municipalidades` | Lee las activas | Lee las activas y la suya | Escribe |
| `personal` | Sin acceso | Lee su municipalidad | Escribe |
| `vecinos` | Lee su fila y cambia `canal_preferido` | Lee | Escribe el resto |
| `predios`, `deudas` | Lee las propias | Lee | Escribe |
| `pagos` | Lee los propios | Lee | Escribe |
| `recordatorios` | Lee los propios | Lee | Escribe |
| `reclamos` | Lee y crea los propios | Lee y cambia `estado`, `area` y `plazo` | Elimina |
| `obras` | Lee todas | Crea y actualiza las suyas | Elimina |

`anon` no tiene acceso a ninguna tabla. Un pago solo se confirma desde el servidor, nunca desde el cliente.

El bucket privado `evidencias` usa la ruta `{municipalidad_id}/{user_id}/{archivo}`. El vecino sube a su carpeta, el personal lee las de su municipalidad y nadie reemplaza ni borra evidencias desde el cliente.

Al agregar una tabla: incluye `municipalidad_id`, activa RLS y revoca los permisos de `anon` y `authenticated`, porque Supabase los concede por defecto en tablas nuevas.

## Recordatorios

`supabase/functions/enviar-recordatorios` procesa los recordatorios con estado `programado` cuya fecha ya pasó. Requiere `Authorization: Bearer <RECORDATORIOS_SECRETO>` y falla cerrada si el secreto no existe.

**El envío es simulado:** `enviarPorCanal` solo registra el intento y devuelve éxito, así que los recordatorios quedan como `enviado` sin que salga ningún mensaje. No se debe programar en producción hasta conectar un proveedor. Falta también el cron que la invoque.

## Comandos

```bash
pnpm install
pnpm mobile
pnpm web
pnpm typecheck
pnpm test
pnpm build:web
```

Base de datos local, con Docker en marcha:

```bash
supabase start
supabase db reset
```
