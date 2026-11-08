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
| Sin smartphone (23, en construcción) | `/sin-smartphone` | `app/sin-smartphone.tsx` |
| Privacidad y mis datos (22, en construcción) | `/privacidad` | `app/privacidad.tsx` |
| Inicio (04) | `/inicio` | `app/(tabs)/inicio/index.tsx` |
| Recordatorios (09) | `/inicio/recordatorios` | `app/(tabs)/inicio/recordatorios.tsx` |
| Detalle del aviso (10) | `/avisos/[id]` | `app/avisos/[id].tsx` |
| Cómo llegan los avisos (11) | `/avisos/como-llegan` | `app/avisos/como-llegan.tsx` |
| Atención humana (14) | `/atencion-humana` | `app/atencion-humana.tsx` |
| Mi cuenta municipal (05) | `/cuenta` | `app/(tabs)/cuenta/index.tsx` |
| Detalle de la deuda (06) | `/cuenta/deuda/[id]` | `app/(tabs)/cuenta/deuda/[id].tsx` |
| Confirma tu pago (07) | `/pago/confirmar` | `app/pago/confirmar.tsx` |
| Constancia de pago (08) | `/pago/constancia` | `app/pago/constancia.tsx` |
| Mi perfil (21, en construcción) | `/perfil` | `app/perfil.tsx` |
| Asistente con IA (12) | `/asistente` | `app/(tabs)/asistente.tsx` |
| Simulación de cuotas (13) | `/simulacion-cuotas` | `app/simulacion-cuotas.tsx` |
| Reclamos | `/reclamos` | `app/(tabs)/reclamos.tsx` |
| Obras | `/obras` | `app/(tabs)/obras.tsx` |

Flujo de entrada:

- Entrada (se elige la municipalidad), ingresa a tu cuenta, tus datos tus reglas, inicio.
- Desde la entrada, "No tengo cuenta ni smartphone propio" lleva a sin smartphone.

El ingreso es simulado: los campos vienen llenos con los datos de ejemplo y cualquier código de 6 dígitos sirve. No se envía ningún SMS.

`src/sesion.tsx` guarda la municipalidad elegida en memoria y filtra todos los datos por ella.

Las pestañas son Inicio, Mi cuenta, Asistente, Reclamos y Obras. El pago es simulado: al confirmar, `registrarPagoSimulado` crea pagos en memoria con estado `pendiente` (solo el servidor confirma pagos), las deudas se ven como pagadas hasta cerrar la app y se abre la constancia con un QR dibujado, que no codifica nada. Los plazos, vencimientos y fechas de pago usan `HOY_EJEMPLO` (1 nov 2026) en vez de la fecha del teléfono.

El asistente no usa IA: `responderAsistente` (`packages/shared/src/asistente.ts`) responde con textos fijos si la pregunta menciona cuotas o la multa, y con un mensaje que orienta a las preguntas sugeridas o a hablar con una persona en cualquier otro caso. La conversación vive solo en la pantalla. La simulación de cuotas usa las deudas pendientes (o solo las vencidas) y la tasa ilustrativa del prototipo (1 % mensual, cuota fija); es informativa y "Pedir evaluación a Rentas" no envía nada. Atención humana es simulada: el tiempo de espera es de ejemplo y no hay nadie conectado; solo promete compartir la consulta con el asistente si el vecino lo autorizó en el consentimiento.

Recordatorios vive dentro de la pestaña Inicio; el detalle del aviso y "Cómo llegan los avisos" se abren encima de las pestañas. Los títulos y mensajes de los avisos salen de `packages/shared/src/avisos.ts` con los datos de la deuda y el `nombreCorto` de la obra (si la obra no lo tiene, el mensaje no la menciona). El canal elegido en "¿Por dónde te avisamos?" se guarda en memoria por municipalidad y empieza con el canal preferido del vecino. Los mensajes de la pantalla 11 son ejemplos: no se envía nada.

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
