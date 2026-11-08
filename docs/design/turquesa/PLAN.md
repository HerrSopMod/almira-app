# Plan de migración al estilo turquesa

Son 6 etapas para Claude Code. Cada etapa va en su propia rama, termina con
`pnpm typecheck`, `pnpm test` y `pnpm build:web` en verde, y se integra con un PR **a
`main`**. No encadenes PRs, para que no se repita lo de los PR #6 a #9.

| Etapa | Rama | Qué cambia |
| --- | --- | --- |
| 1 | `feat/turquesa-base` | `CLAUDE.md`, tokens, solo Inter, íconos, componentes base, barras y estilos base del panel |
| 2 | `feat/turquesa-ingreso-pagos` | Pantallas 01 a 08: ingreso con Google o DNI, Inicio, Pagar y constancia |
| 3 | `feat/turquesa-avisos-reclamos` | Pantallas 09 a 18 y 21 a 23 (menos el mapa) |
| 4 | `feat/mapa-real` | Mapa real: migración, datos, `mapa.ts`, pantallas 16, 19 y 20, y web-06 |
| 5 | `feat/turquesa-panel` | Las 9 páginas del panel web |
| 6 | `fix/turquesa-revision` | Revisión final: colores viejos, textos de Stitch, capturas |

Antes de cada etapa: `git checkout main`, `git pull` y `git checkout -b <rama>`. Después
escribe `/clear` en Claude Code y pega el prompt de la etapa.

---

## Etapa 1 · Base visual

```text
Vamos a migrar Almira al estilo turquesa. Lee completos docs/design/turquesa/LEEME.md,
PANTALLAS.md y PLAN.md. Primero muéstrame tu plan y espera mi OK.

Esta etapa es solo la base, sin rehacer pantallas:

1. CLAUDE.md: reemplaza la sección "Reglas de diseño" por el bloque de PLAN.md
   ("Reglas de diseño nuevas para CLAUDE.md"). En "Reglas de producto", cambia la línea de
   docs/design/prototipo por: "No inventes funciones fuera de las pantallas de
   docs/design/turquesa y docs/design/prototipo." No toques las demás secciones.
2. packages/shared/src/tokens.ts: usa los colores, tipografía, medidas y radios de
   LEEME.md con los nombres de su tabla. Quita los tokens que ya no apliquen (header,
   backgroundPink, notice1-3, tonos vino, displayFontFamily) y actualiza a quienes los
   usan. Los tokens drawing* del mapa se quedan hasta la etapa 4. Ajusta
   panelSizes/panelTypography a LEEME.md → Panel web.
3. Fuente: solo Inter. Quita @expo-google-fonts/poppins y @fontsource/poppins y sus
   imports. Los montos usan tabular-nums.
4. Íconos: MaterialIcons de @expo/vector-icons en la app. En el panel, SVG de Material
   Symbols en iconos.tsx. No agregues paquetes de íconos.
5. Componentes base de la app (src/components): Boton (primario, secundario, terciario,
   google, peligro suave), Tarjeta, FilaDato, Destacado, Nota, Insignia (ok, warn, bad,
   info, neutral), Chip, Segmentado, Campo, CajaIcono, Avance, Interruptor, Casilla,
   Radio, LineaTiempo y Escalera, con las medidas de LEEME.md. BarraSuperior con las
   variantes "raíz" (logo, ALMIRA, título, campana que va a Recordatorios y avatar que va
   a Mi perfil) y "detalle" (flecha, título, acción opcional).
6. Barra inferior: Inicio, Pagar, Reclamos, Obras y Asistente, en ese orden y con los
   íconos de LEEME.md. "Pagar" usa la ruta actual (tabs)/cuenta.
7. Panel web: variables y estilos base de estilos.css (barra lateral blanca, tarjetas,
   tablas, botones, insignias), como en docs/design/turquesa/fuentes/estilos.css. Todo
   sale de los tokens.

Al terminar, todas las pantallas deben verse turquesa aunque su diseño cambie en las
etapas 2, 3 y 5. Corre pnpm typecheck, pnpm test y pnpm build:web. Haz commits pequeños
con formato tipo(ámbito): descripción.
```

## Etapa 2 · Ingreso, Inicio y Pagar

```text
Sigue con la migración turquesa. Lee docs/design/turquesa/LEEME.md y PANTALLAS.md, y
mira las imágenes que PANTALLAS.md indica para las pantallas 01 a 08 (maquetas de
docs/design/turquesa/movil y pantallas 1 a 7 de Stitch). Los textos salen de
docs/design/prototipo/TEXTOS.md. Primero muéstrame tu plan y espera mi OK.

- Ingreso nuevo: Entrada (01) → Ingreso (Stitch 1, Google o DNI) → Código (Stitch 2) →
  Vincular DNI (Stitch 3, solo tras Google) → Elegir municipalidad (Stitch 4) →
  Consentimiento (03) → Inicio. Crea las rutas nuevas que pide PANTALLAS.md. Google se
  simula mientras no haya Supabase; deja un único punto (una función en src/sesion.tsx)
  donde luego se conectará supabase.auth.signInWithOAuth.
- Inicio (04) según Stitch 5, con los datos de Rosa y sin la cuadrícula de accesos.
- Pagar (05) según la parte superior de Stitch 7, con casillas y total que se recalcula.
  Confirma tu pago (07) según la parte inferior de Stitch 7. Detalle de la deuda (06)
  según Stitch 6. Constancia (08) según su maqueta.
- No copies textos de Stitch: respeta "Lo que no se copia de Stitch" en LEEME.md.
- Actualiza docs/ARCHITECTURE.md con las rutas nuevas y agrega pruebas en shared si
  agregas lógica (por ejemplo, el total de lo seleccionado).

Corre los tres comandos y haz commits pequeños.
```

## Etapa 3 · Avisos, asistente, reclamos y perfil

```text
Sigue con la migración turquesa. Lee docs/design/turquesa/LEEME.md y PANTALLAS.md.
Rehaz las pantallas 09 a 15, 17, 18 y 21 a 23 según la imagen que indica PANTALLAS.md
(maqueta o Stitch 8 a 10). Rehaz también la 16 según su maqueta, pero deja el minimapa
como un recuadro "Mapa" provisional, porque el mapa real llega en la etapa 4. Los textos
salen de TEXTOS.md, con los cambios que lista PANTALLAS.md. Primero muéstrame tu plan y
espera mi OK.

- El asistente se llama "Asistente" y sigue con reglas fijas. Agrega la nota de que es un
  prototipo con respuestas fijas.
- Recordatorios: canales con interruptores, no con radio.
- Reclamos: sin teléfono; "Hablar con una persona" lleva a Atención humana.
- Escalera de avisos con los colores de paso de LEEME.md.

Corre los tres comandos y haz commits pequeños.
```

## Etapa 4 · Mapa real

```text
Implementa el mapa real de obras siguiendo docs/design/turquesa/MAPA.md al pie de la
letra. Mira las maquetas 16, 19 y 20 de docs/design/turquesa/movil y la web-06 de
docs/design/turquesa/web. Primero muéstrame tu plan y espera mi OK.

- Migración nueva con latitud y longitud en obras, tipo Obra, datos de ejemplo y
  seed.sql. Lee docs/ARCHITECTURE.md antes de tocar el esquema.
- packages/shared/src/mapa.ts con sus pruebas.
- App: instala react-native-webview con pnpm exec expo install desde apps/mobile.
  MapaObras.tsx (WebView) y MapaObras.web.tsx (iframe). Pantallas 19, 20 y el minimapa
  de 16.
- Panel: leaflet@1.9.4, react-leaflet@5 y @types/leaflet. Tarjeta "Vista del vecino" en
  web-06.
- La atribución de OpenStreetMap siempre visible. Si el mapa no carga, muestra la nota y
  deja la lista.
- Borra el dibujo viejo del mapa y sus tokens drawing* que ya nadie use.

Corre los tres comandos. Luego dime cómo probarlo en el teléfono y en el navegador.
```

## Etapa 5 · Panel web

```text
Rehaz las 9 páginas del panel web según las maquetas web-01 a web-09 de
docs/design/turquesa/web (el HTML de cada una está en docs/design/turquesa/fuentes/web).
Mantén estado.tsx, los contadores y todas las acciones en memoria. Gráficos: barras con
su cifra escrita y leyenda cuando hay dos series (LEEME.md). Todo con tokens; nada de
hex sueltos en el CSS. Primero muéstrame tu plan y espera mi OK.

Corre los tres comandos y haz commits pequeños.
```

## Etapa 6 · Revisión final

```text
Haz una revisión final de la migración turquesa:
1. Busca en apps/ y packages/ colores viejos (#C00000, #800404, #F7ECEC, #FFFFCC,
   #E9C1C6, #9A5563, #5B1428, #F4A6A6) y el uso de Poppins. No debe quedar ninguno.
2. Busca textos de Stitch prohibidos (LEEME.md → "Lo que no se copia de Stitch") y
   nombres o teléfonos de municipalidades escritos en la interfaz.
3. Revisa que cada pantalla tenga como máximo un Destacado y que no haya botones dentro
   de tarjetas.
4. Levanta el panel y la app en Expo web y compara cada pantalla con su imagen de
   docs/design/turquesa. Haz una lista de diferencias y corrígelas.
Corre los tres comandos.
```

---

## Reglas de diseño nuevas para CLAUDE.md

```markdown
## Reglas de diseño

- El aspecto lo manda `docs/design/turquesa`: lee `LEEME.md` y sigue la imagen que indica `PANTALLAS.md` para cada pantalla. Los textos y recorridos salen de `docs/design/prototipo/TEXTOS.md`, con los cambios de `PANTALLAS.md`. De Stitch se toma el estilo, nunca sus textos.
- Usa los tokens de `@almira/shared`. No escribas colores ni medidas sueltas.
- Fondo `#FFFFFF`, color principal `#0B7F86` y texto `#0F2A2E`. Solo Inter, con cifras tabulares en montos.
- Botones de 52 px y ancho completo, con márgenes de 20 px. No los pongas dentro de tarjetas.
- Máximo un bloque `Destacado` por pantalla. Los colores de estado solo van en insignias y estados.
- Montos con `formatearSoles`, alineados a la derecha en filas y tablas.
- El mapa de obras es OpenStreetMap con Leaflet (`MAPA.md`) y siempre muestra la atribución.
```
