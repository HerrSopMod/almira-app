# Almira

Monorepo pnpm: app de vecinos (`apps/mobile`), panel municipal (`apps/web`), tipos y tokens (`packages/shared`) y backend (`supabase`). Lee `docs/ARCHITECTURE.md` antes de cambiar la estructura o el esquema.

## Comandos

- `pnpm install`: instala todo.
- `pnpm typecheck`, `pnpm test`, `pnpm build:web`: corre los tres antes de hacer commit.
- `pnpm mobile`, `pnpm web`: levantan cada app.

## Reglas de producto

- Almira es la marca fija. La municipalidad es un dato seleccionable: nunca escribas el nombre, teléfono o logo de una municipalidad en el código de la interfaz.
- No inventes funciones fuera de las pantallas de `docs/design/prototipo`.
- No afirmes en la interfaz certificaciones, validaciones o integraciones que la app no tenga.
- Textos en español de Perú, tratando al vecino de "tú".

## Reglas de diseño

- La fuente de verdad del diseño es `docs/design/prototipo`: lee `LEEME.md`, copia los textos de `TEXTOS.md` y sigue las imágenes. Las pantallas de Stitch quedan solo como referencia anterior.
- Usa los tokens de `@almira/shared`. No escribas colores ni medidas sueltas.
- Fondo `#FFFFFF`, encabezados `#800404` y color primario `#C00000`. Los tonos vino (`#E9C1C6`, `#9A5563`, `#5B1428`) solo van en la escalera de avisos.
- Poppins para montos, marca y títulos; Inter para etiquetas, botones y texto.
- Las medidas de botones, tarjetas y márgenes salen de las imágenes del prototipo.
- Montos con `formatearSoles`. En filas y tablas van alineados a la derecha; los montos destacados de tarjetas siguen la alineación de la imagen del prototipo.

## Reglas de datos

- Toda tabla nueva lleva `municipalidad_id` y RLS, y revoca los permisos de `anon` y `authenticated`.
- Permite escrituras desde el cliente solo con permisos por columna y política explícita.
- Los pagos solo se confirman desde el servidor.
- Nunca registres en logs teléfonos, DNI ni otros datos personales.

## Forma de trabajo

- Commits pequeños en español, con formato `tipo(ámbito): descripción`.
- Pregunta antes de instalar paquetes globales.
- Expo fija versiones: agrega dependencias móviles con `pnpm exec expo install` desde `apps/mobile`.
- Mantén una sola versión de TypeScript en el monorepo.
