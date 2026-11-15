# Almira

Monorepo pnpm: app de vecinos en Flutter (`apps/almira_flutter`), app de vecinos anterior en Expo (`apps/mobile`, solo como referencia), panel municipal (`apps/web`), tipos y tokens (`packages/shared`) y backend (`supabase`). Lee `docs/ARCHITECTURE.md` antes de cambiar la estructura o el esquema.

## Comandos

- `pnpm install`: instala todo.
- `pnpm typecheck`, `pnpm test`, `pnpm build:web`: corre los tres antes de hacer commit.
- `pnpm mobile`, `pnpm web`: levantan la app de Expo y el panel.
- App Flutter, desde `apps/almira_flutter`: `flutter analyze`, `flutter test` y `flutter run` (ver su `README.md`).

## Reglas de producto

- Almira es la marca fija. La municipalidad es un dato seleccionable: nunca escribas el nombre, teléfono o logo de una municipalidad en el código de la interfaz.
- No inventes funciones fuera de las pantallas de `docs/design/turquesa` y `docs/design/prototipo`.
- No afirmes en la interfaz certificaciones, validaciones o integraciones que la app no tenga.
- Textos en español de Perú, tratando al vecino de "tú".
- La interfaz se ve como un producto real: sin «Prototipo académico» ni «Datos ficticios». Nada de subtítulos u observaciones obvias: textos mínimos.
- Excepción en la app Flutter: sin Supabase configurado abre en modo demostración y lo marca con la etiqueta «Demostración». Nunca muestra datos de ejemplo como si fueran oficiales.

## Reglas de diseño

- El aspecto lo manda `docs/design/turquesa`: lee `LEEME.md` y sigue la imagen que indica `PANTALLAS.md` para cada pantalla. Los textos y recorridos salen de `docs/design/prototipo/TEXTOS.md`, con los cambios de `PANTALLAS.md`. De Stitch se toma el estilo, nunca sus textos.
- Usa los tokens de `@almira/shared`. No escribas colores ni medidas sueltas.
- Fondo `#FFFFFF`, color principal `#0B7F86` y texto `#0F2A2E`. Solo Inter, con cifras tabulares en montos (la app Flutter usa Plus Jakarta Sans, que también las tiene).
- App móvil: botones de 52 px y ancho completo, con márgenes de 20 px. No los pongas dentro de tarjetas.
- Panel web: se permiten botones pequeños dentro de tablas y tarjetas, como en las maquetas `docs/design/turquesa/web` (medidas en `LEEME.md` → Panel web).
- Máximo un bloque `Destacado` por pantalla. Los colores de estado solo van en insignias y estados.
- Montos con `formatearSoles`, alineados a la derecha en filas y tablas.
- El mapa de obras es OpenStreetMap con Leaflet (`MAPA.md`) y siempre muestra la atribución.

### App Flutter

- Colores, medidas y tipografía salen de `lib/app/theme`. No escribas colores sueltos en los widgets.
- Un solo mapa: `MapaAlmira` (`flutter_map` con OpenStreetMap), siempre con atribución.
- Fechas y plazos con la fecha real del teléfono (`relojProvider`), nunca con una fecha fija.
- Cada pantalla con datos cubre carga, vacío, error y sin conexión (`CuerpoAsync`).
- Íconos: paquete Iconsax (diseñados a mano, no generados con IA), siempre desde `lib/app/theme/iconos.dart` (no uses otros paquetes de íconos ni logos de marcas de terceros sin permiso). Los accesos y las filas de datos llevan el ícono en un círculo tintado (`IconoColor`) con los acentos de `app_colors.dart`; los colores de estado siguen reservados a insignias y estados.
- Filtros por fecha: `GrupoFiltroFechas` (periodos rápidos y calendario) con `FiltroFechas`; la fecha de hoy sale de `relojProvider`.
- La foto de perfil se guarda en el bucket privado `avatares` de Supabase (`foto_perfil.dart`); en modo demostración no se puede cambiar.
- Pestañas raíz (Inicio, Pagar, Reclamos, Obras, Asistente): cabecera turquesa sólida y baja detrás de la barra de estado, con el título y las acciones (sin logo ni «Almira»: ya se sabe en qué app estás), y el contenido en una hoja blanca de esquinas superiores de 20 montada sobre ella (`CabeceraMarca`, `HojaBlanca`, `CuerpoAsync(cabecera: …)`). Solo Inicio lleva tarjeta flotante, con la carita de `cara_saldo.dart`.
- Pantallas de detalle: `AppBar` normal; el tema la pinta turquesa compacta con flecha y título en blanco. Ingreso: parte superior clara (40 % de la pantalla) con círculos turquesa suaves, el logo en un círculo blanco, el nombre y una frase, y el formulario debajo en una hoja blanca.
- Barra inferior: Inicio, Pagar, Asistente (botón central turquesa con robot blanco), Reclamos y Obras. El orden visual no cambia las ramas del router.
- Pantalla de carga: splash nativo y `PantallaCarga` en turquesa con el ícono blanco al centro (112 dp), sin franja blanca al entrar.
- Plazos en texto gris («Vence el 30 de noviembre»), en rojo solo si venció; insignias solo para estados reales. Fichas con rótulo arriba y valor debajo; solo los montos a la derecha.

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
