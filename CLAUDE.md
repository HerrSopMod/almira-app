# Almira

Monorepo pnpm: app de vecinos (`apps/mobile`), panel municipal (`apps/web`), tipos y tokens (`packages/shared`) y backend (`supabase`). Lee `docs/ARCHITECTURE.md` antes de cambiar la estructura o el esquema.

## Comandos

- `pnpm install`: instala todo.
- `pnpm typecheck`, `pnpm test`, `pnpm build:web`: corre los tres antes de hacer commit.
- `pnpm mobile`, `pnpm web`: levantan cada app.

## Reglas de producto

- Almira es la marca fija. La municipalidad es un dato seleccionable: nunca escribas el nombre, teléfono o logo de una municipalidad en el código de la interfaz.
- No inventes funciones fuera de las pantallas de `docs/design/turquesa` y `docs/design/prototipo`.
- No afirmes en la interfaz certificaciones, validaciones o integraciones que la app no tenga.
- Textos en español de Perú, tratando al vecino de "tú".

## Reglas de diseño

- El aspecto lo manda `docs/design/turquesa`: lee `LEEME.md` y sigue la imagen que indica `PANTALLAS.md` para cada pantalla. Los textos y recorridos salen de `docs/design/prototipo/TEXTOS.md`, con los cambios de `PANTALLAS.md`. De Stitch se toma el estilo, nunca sus textos.
- Usa los tokens de `@almira/shared`. No escribas colores ni medidas sueltas.
- Fondo `#FFFFFF`, color principal `#0B7F86` y texto `#0F2A2E`. Solo Inter, con cifras tabulares en montos.
- App móvil: botones de 52 px y ancho completo, con márgenes de 20 px. No los pongas dentro de tarjetas.
- Panel web: se permiten botones pequeños dentro de tablas y tarjetas, como en las maquetas `docs/design/turquesa/web` (medidas en `LEEME.md` → Panel web).
- Máximo un bloque `Destacado` por pantalla. Los colores de estado solo van en insignias y estados.
- Montos con `formatearSoles`, alineados a la derecha en filas y tablas.
- El mapa de obras es OpenStreetMap con Leaflet (`MAPA.md`) y siempre muestra la atribución.

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
