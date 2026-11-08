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
| Inicio | `/inicio` | `app/(tabs)/inicio.tsx` |
| Detalle de deuda | `/deuda/[id]` | `app/deuda/[id].tsx` |
| Pagar | `/pagar` | `app/(tabs)/pagar.tsx` |
| Recordatorios | `/recordatorios` | `app/recordatorios.tsx` |
| Asistente | `/asistente` | `app/(tabs)/asistente.tsx` |
| Reclamos | `/reclamos` | `app/(tabs)/reclamos.tsx` |
| Obras | `/obras` | `app/(tabs)/obras.tsx` |

Flujo de entrada:

- Entrada (se elige la municipalidad), ingresa a tu cuenta, tus datos tus reglas, inicio.
- Desde la entrada, "No tengo cuenta ni smartphone propio" lleva a sin smartphone.

El ingreso es simulado: los campos vienen llenos con los datos de ejemplo y cualquier código de 6 dígitos sirve. No se envía ningún SMS.

`src/sesion.tsx` guarda la municipalidad elegida en memoria y filtra todos los datos por ella.

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
