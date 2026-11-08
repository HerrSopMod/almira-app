# Almira · Guía de estilos turquesa

Esta carpeta define **el aspecto** de Almira. Sale del diseño de Stitch "Civic Clarity"
(`docs/design/stitch_almira_gesti_n_tributaria_municipal`) y lo completa para todas las
pantallas de la app y del panel web.

## Qué manda en cada cosa

| Tema | Fuente que manda |
| --- | --- |
| Colores, tipografía, medidas y componentes | Esta guía (`docs/design/turquesa/LEEME.md`) |
| Cómo se ve cada pantalla | `PANTALLAS.md` dice qué imagen seguir: una maqueta de `turquesa/movil` o `turquesa/web`, o una pantalla de Stitch adaptada |
| Textos y datos de ejemplo | `docs/design/prototipo/TEXTOS.md`, salvo los cambios que lista `PANTALLAS.md` |
| Recorridos (qué pantalla lleva a cuál) | `docs/design/prototipo/general/00-mapa-de-flujos.png` y `PANTALLAS.md` |
| Mapa real de obras | `MAPA.md` |

Las imágenes rojas de `docs/design/prototipo` ya **no** mandan en el aspecto: solo sirven
para textos y recorridos.

De Stitch se toma el estilo, **nunca sus textos**. Stitch inventa datos y promesas que
Almira no cumple (ver «Lo que no se copia de Stitch», al final).

## Principios

1. **Claridad cívica.** Fondo blanco, líneas finas y texto de alto contraste. Nada de
   degradados, sombras de adorno ni tarjetas dentro de tarjetas.
2. **Pensada para adultos mayores.** El texto de lectura mide como mínimo 14 px y el de
   trámites 16 px. Las zonas de toque miden 48 px o más.
3. **Un solo bloque Destacado por pantalla.** Va con fondo `highlight`, para lo más
   importante de esa pantalla.
4. **Los colores de estado solo van en insignias y estados.** Verde, ámbar y rojo nunca
   rellenan tarjetas ni botones.
5. **Los montos se leen de un vistazo.** Siempre `S/ 0.00` con `formatearSoles`, cifras
   tabulares y alineados a la derecha en filas y tablas.

## Color

| Token | Hex | Uso |
| --- | --- | --- |
| `primary` | `#0B7F86` | Botón primario, enlaces, pestaña activa, íconos de acción |
| `primaryPressed` | `#00646A` | Botón presionado; título del bloque Destacado |
| `primaryDisabled` | `#A9D2D4` | Botón primario deshabilitado (texto blanco) |
| `onPrimary` | `#FFFFFF` | Texto sobre `primary` |
| `accent` | `#2CC5C0` | Solo barras de avance y plazos (no interactivo) |
| `highlight` | `#E3F6F5` | Fondo del bloque Destacado (máximo 1 por pantalla) y del módulo activo del panel |
| `subtle` | `#F2F8F8` | Fondo de cajas de ícono, controles segmentados y burbujas recibidas |
| `background` / `surface` | `#FFFFFF` | Fondo de toda pantalla y tarjeta |
| `panelBackground` | `#F7FAFA` | Fondo del área de contenido del panel web |
| `text` | `#0F2A2E` | Texto principal |
| `textSecondary` | `#5B6B70` | Etiquetas, fechas, ayudas, íconos inactivos |
| `border` | `#D6E3E4` | Bordes de 1 px y divisores |
| `track` | `#E6EFF0` | Fondo de barras de avance |
| `success` · `successSoft` · `successText` | `#2E9E6B` · `#EAF6F0` · `#1F7A50` | Pagada, Resuelto, Concluida |
| `warning` · `warningSoft` · `warningText` | `#C98A00` · `#FBF5E6` · `#8A5E00` | Por vencer, En atención, Quedan N d |
| `danger` · `dangerSoft` · `dangerText` | `#D64545` · `#FAEAEA` · `#B42F2F` | En mora, Vencido, alerta activa |
| `chart1` · `chart2` | `#0B7F86` · `#7CC4C8` | Gráficos: serie resaltada y serie de apoyo |
| `scrim` | `rgba(15, 42, 46, 0.4)` | Fondo detrás de hojas y diálogos |

En las insignias, el texto usa la variante `…Text`, no el color base, para que se lea bien
(contraste AA). El color base se usa en el punto de la insignia, en los marcadores del
mapa y en el borde de la alerta activa.

**Escalera de avisos:** el paso 1 usa `highlight` con `primaryPressed`, el paso 2 usa
`warningSoft` con `warningText` y el paso 3 usa `dangerSoft` con `dangerText`. Los tonos
vino del prototipo desaparecen.

**Gráficos:** `chart2` sobre blanco tiene poco contraste, así que toda barra lleva su
cifra escrita y todo gráfico de dos series lleva leyenda.

## Tipografía

Solo **Inter** (400, 500, 600 y 700). Poppins sale del proyecto. Montos y tablas con
`fontVariant: ['tabular-nums']` (en CSS, `font-variant-numeric: tabular-nums`).

| Token | Tamaño / interlineado | Peso | Uso |
| --- | --- | --- | --- |
| `displayCurrency` | 32 / 38, espaciado −0.64 | 700 | Monto principal de la pantalla |
| `brand` | 36 / 44, espaciado −0.72 | 700 | Palabra "Almira" en Entrada |
| `headlineLg` | 24 / 32, espaciado −0.24 | 700 | Título de pantalla |
| `headlineMd` | 20 / 28 | 600 | Título de sección grande |
| `headlineSm` | 18 / 24 | 600 | Título de la barra superior y de tarjetas |
| `bodyLg` | 16 / 24 | 400 | Texto de trámite e instrucciones |
| `bodyLgMedium` | 16 / 24 | 500 | Títulos de filas y opciones |
| `bodyMd` | 14 / 20 | 400 | Texto de lectura y descripciones |
| `bodyMdMedium` | 14 / 20 | 500 | Etiquetas de campo |
| `button` | 16 / 20 | 600 | Botones |
| `labelSm` | 12 / 16, espaciado 0.24 | 600 | Insignias y rótulos |
| `overline` | 12 / 16, espaciado 0.72, mayúsculas | 600 | Encabezados de sección ("MIS DERECHOS") |
| `caption` | 12 / 16 | 400 | Ayudas y pies |
| `tabLabel` | 11 / 14 | 500 | Etiquetas de la barra inferior |

**Panel web:** título de página 24 / 30 (700), título de tarjeta 16 / 22 (600), cifra de
indicador 28 / 34 (700), texto de tabla 13 / 18, encabezado de tabla 11 / 16 (600, en
mayúsculas, espaciado 0.66) y menú 14 / 20 (500; 600 cuando está activo).

## Espacios, radios y medidas

- **Márgenes laterales de 20 px** en toda pantalla móvil. La separación entre bloques es
  de 16 px, o de 12 px en listas densas.
- **Radios:** 6 px en insignias, 8 px en ítems del menú web, 10 px en cajas de ícono,
  12 px en botones, campos y tarjetas, 16 px en tarjetas grandes, mapa y borde superior de
  la barra inferior, y círculo completo en chips y avatar.
- **Medidas:** botón 52 px (terciario 48), campo 52 px, barra superior 56 px, barra
  inferior 64 px más el área segura, caja de ícono 40 px (grande 56), avatar 36 px (grande
  56), insignia 24 px, chip 36 px (web 32), barra de avance 6 px, interruptor 44 × 26,
  radio y casilla 22 px, mapa móvil 300 px de alto.
- **Bordes:** 1 px `border`. Foco y selección: 1.5 px `primary`. No hay sombras, salvo el
  marcador del mapa.
- Al final de cada lista con barra inferior, agrega un relleno igual al alto de la barra
  más el área segura más 20 px.

## Componentes

**Barra superior.** Hay dos variantes:
- *Raíz de pestaña* (Inicio, Pagar, Reclamos, Obras, Asistente): logo de 32 px, el rótulo
  "ALMIRA" (11 px, 600, `primary`) sobre el nombre de la pestaña (18 px, 600), y a la
  derecha la campana (lleva a Recordatorios) y el avatar con iniciales (lleva a Mi perfil).
- *Detalle:* flecha atrás (zona de 48 px) y título de 18 px, alineado a la izquierda. A la
  derecha puede ir una acción opcional, o "Paso N de M" en `caption`.

Las dos van en blanco, con una línea inferior de 1 px. La barra vino del prototipo
desaparece.

**Barra inferior.** Cinco pestañas, en este orden: **Inicio** (`home`), **Pagar**
(`payments`), **Reclamos** (`report`), **Obras** (`construction`) y **Asistente**
(`support_agent`). La activa va en `primary` con el ícono relleno; las inactivas, en
`textSecondary`. Lleva una línea superior de 1 px.

**Botones.** Siempre de ancho completo, con márgenes de 20 px, y nunca dentro de tarjetas.
- *Primario:* relleno `primary`, texto blanco.
- *Secundario:* fondo blanco, borde de 1.5 px `primary`, texto `primary`.
- *Terciario:* sin borde, texto `primary` 500.
- *Google:* fondo blanco, borde de 1 px `border` y logo de Google.
- *Peligro suave (Cerrar sesión):* secundario con borde `border` y texto `dangerText`.

Si hay varios botones, van apilados con 8 px de separación: primero el primario, luego el
secundario y al final el terciario.

**Tarjeta.** Blanca, con borde de 1 px y radio de 12 px, y relleno de 16 px (20 px en la
grande). Para agrupar filas se usa *una* tarjeta con divisores internos de 1 px, nunca
tarjetas anidadas.

**Fila clave–valor.** La etiqueta va a la izquierda en `textSecondary` y el valor a la
derecha en 500 con cifras tabulares. La fila "Total" va en 16 px y su monto en 18 px 700.

**Destacado.** Fondo `highlight`, radio de 12 px y relleno de 16 px. Lleva un ícono
`primary` y título en `primaryPressed`. Máximo uno por pantalla.

**Nota.** Ícono de 20 px y texto de 14 px, ambos en `textSecondary`, sin fondo. La
variante *con borde* lleva borde de 1 px y radio de 12 px. Se usa para avisos legales,
explicaciones y "Datos de ejemplo".

**Insignia.** 24 px de alto, relleno horizontal de 8 px y radio de 6 px. Lleva un punto
de 6 px y texto `labelSm`. Hay variantes `ok`, `warn`, `bad`, `info` (`highlight` con
`primaryPressed`) y `neutral` (`subtle` con `textSecondary`, sin punto).

**Chip.** 36 px de alto, círculo completo, borde de 1 px. El activo va relleno de
`primary`, con texto blanco y un check opcional.

**Control segmentado.** Fondo `subtle`, radio de 12 px y separación interna de 4 px. La
opción activa va en blanco, con borde de 1 px y texto `primary` 600.

**Campo.** La etiqueta va arriba, en 14 px 500. El campo mide 52 px, con borde de 1 px,
radio de 12 px y texto de 16 px. Con foco, el borde pasa a 1.5 px `primary`.

**Caja de ícono.** 40 × 40 px, radio de 10 px, fondo `subtle` e ícono `primary` de 24 px.

**Avance.** Riel `track` de 6 px con relleno `accent`. Las obras concluidas usan relleno
`success`.

**Línea de tiempo.** Puntos de 22 px unidos por un trazo de 2 px. Hecho: relleno
`primary` con check blanco. Actual: anillo `primary` de 6 px. Pendiente: borde `border`.

**Escalera de avisos.** Tres filas con borde, cada una con un número de 28 px en su color
de paso (ver Color). La fila actual lleva borde de 1.5 px `primary` y el rótulo "Estás
aquí".

**Burbujas (cómo llegan los avisos).** Las recibidas van en `subtle`, con la esquina
superior izquierda de 4 px; las enviadas, en `primary` con texto blanco. Ocupan como
máximo el 84 % del ancho.

**Marcador del mapa.** Píldora de 28 px de alto con el % de avance, borde blanco de 2 px
y sombra suave. Va en `primary` si la obra está en ejecución, en `success` si está
concluida y en `primaryPressed` (algo más grande) si está seleccionada.

**Panel web.**
- *Barra lateral:* blanca, de 248 px, con borde derecho de 1 px. Arriba van el logo,
  "Almira" y el nombre de la municipalidad (viene de los datos). Cada módulo mide 40 px;
  el activo va con fondo `highlight` y texto `primaryPressed` 600. El contador va en
  círculo `primary` con texto blanco. Abajo va el usuario.
- *Contenido:* fondo `panelBackground` y márgenes de 24 × 28 px. Las tarjetas son blancas,
  con borde, radio de 12 px y relleno de 18 × 20 px.
- *Tablas:* sin bordes verticales, con encabezado en mayúsculas `textSecondary` y filas
  separadas por 1 px. La fila seleccionada lleva fondo `subtle`.
- *Botones:* 40 px (pequeños, 32 px), con radio de 10 px.

## Íconos

Material Symbols Outlined (los mismos de Stitch). En la app móvil se usa
`MaterialIcons` de `@expo/vector-icons`, que ya está instalado; si un nombre no existe
ahí, se usa el más parecido. En el panel web se usan SVG en línea copiados de Material
Symbols (licencia Apache 2.0) dentro de `iconos.tsx`, sin agregar paquetes. Los íconos
miden 24 px (20 en el menú web y 16 a 18 dentro de insignias y textos).

## Marca

- El logo es un cuadrado `primary` con radio de 9 px (18 px en la versión grande de
  64 px) y una "a" blanca en Inter 700. La palabra "Almira" va en Inter 700.
- Almira es la marca fija. El nombre de la municipalidad siempre viene de los datos
  seleccionados, nunca escrito en la interfaz.

## Lo que no se copia de Stitch

Las pantallas de Stitch traen textos que Almira no puede afirmar. **No se copian:**

- "Validación directa con RENIEC", "Validación biométrica e identidad".
- "Transacción 100 % cifrada según ISO/IEC 27001", "Pago verificado y encriptado",
  "firma digital", "Constancia Oficial… al instante", "Sin comisiones".
- "Toda foto registra automáticamente sello de tiempo y ubicación para fiscalización".
- "Canal seguro municipal · Encriptación ciudadana", "Portal de Transparencia",
  "Descargar resumen trimestral en PDF".
- Teléfonos ("(01) 315-2000", "01-311-8000"), "SAT", "Municipalidad Metropolitana de
  Lima", "Santa Aurora", "Villa Verde" y cualquier otro nombre de municipalidad.
- Los datos de Carlos, S/ 480.50 y febrero 2025. Los datos de ejemplo siguen siendo los
  de Rosa en Lince (`datos-ejemplo.ts`).
