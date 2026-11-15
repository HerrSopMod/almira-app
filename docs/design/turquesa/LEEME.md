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
   degradados, sombras de adorno ni tarjetas dentro de tarjetas. En la app móvil, las
   pestañas y el ingreso llevan arriba una cabecera turquesa sólida con una hoja blanca
   montada sobre ella (ver «Cabecera turquesa y hoja blanca»).
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

**App móvil (Flutter):** escala corta de cuatro tamaños: monto principal 32 / 38 (700),
título 20 / 26 (600), cuerpo 15 / 22 y secundario 13 / 18 en `textSecondary`. El saludo de la
cabecera mide 24 y las etiquetas de la barra inferior, 11. Dentro de una tarjeta se usan como
máximo dos tamaños.

**Panel web (densidad compacta):** título de página 20 / 26 (700) con su subtítulo de
13 / 18, título de tarjeta 15 / 20 (600) con su subtítulo de 12 / 16, rótulo de indicador
12 / 16 (500), cifra de indicador 24 / 30 (700), texto de tabla 13 / 18, encabezado de
tabla 11 / 16 (600, en mayúsculas, espaciado 0.66) y menú 14 / 20 (500; 600 cuando está
activo). Las notas y textos de lectura siguen en 14 px.

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
  marcador del mapa y, en la app móvil, la tarjeta flotante de Inicio, la barra inferior y su
  botón central (sombra muy suave: `text` al 8 %, desenfoque de 16 px).
- Al final de cada lista con barra inferior, agrega un relleno igual al alto de la barra
  más el área segura más 20 px.

## Componentes

**Barra superior.** Hay dos variantes:
- *Raíz de pestaña* (Inicio, Pagar, Reclamos, Obras, Asistente): en la app móvil es la
  cabecera turquesa (ver «Cabecera turquesa y hoja blanca»). En la app Expo de referencia:
  logo de 32 px, el rótulo "ALMIRA" sobre el nombre de la pestaña, campana y avatar, en blanco.
- *Detalle* (deuda, reclamo, obra, pago y demás pantallas que se abren encima): barra
  turquesa compacta de 56 px, sin línea, con la flecha atrás (zona de 48 px) y el título de
  20 px en blanco, alineado a la izquierda. A la derecha puede ir una acción opcional.

La barra vino del prototipo desaparece.

**Barra inferior.** Blanca, con esquinas superiores de 20 px, sombra muy suave y el área
segura respetada. Cinco destinos, en este orden: **Inicio**, **Pagar**, **Asistente** (al
centro), **Reclamos** y **Obras**. Las rutas no cambian, solo el orden en pantalla.
- *Asistente:* botón circular `primary` de 56 px con anillo blanco de 4 px, que sobresale
  18 px de la barra. Lleva un robot blanco de líneas limpias de la misma familia de íconos,
  sin cara sonriente. Activo: `primaryPressed`. Su etiqueta va alineada con las demás.
- *Resto:* ícono redondeado de 24 px y etiqueta de 11 px. La activa va en `primary`, con el
  ícono relleno y una línea corta de 24 × 3 px arriba; las inactivas, en `textSecondary`.
- Animación de 200 ms, que se apaga con «reducir movimiento». Cada destino lleva su etiqueta
  accesible y una zona de toque de 48 px o más.

**Cabecera turquesa y hoja blanca (app móvil).** Es el patrón principal de las pestañas:
- *Cabecera:* bloque `primary` sólido que empieza detrás de la barra de estado (íconos del
  sistema claros). Arriba, el logo blanco de 28 px y el título de la pestaña en blanco, de
  20 px; a la derecha, la campana o el perfil. Debajo puede ir contenido en blanco: el saludo
  «Hola, {nombre}» de 24 px en Inicio o el total pendiente de 32 px en Pagar. Todo lo que va
  sobre turquesa es blanco (5,1:1, AA); la etiqueta «Demostración» va en blanco con texto
  `warningText`.
- *Hoja blanca:* el contenido va en una hoja `surface` con esquinas superiores de 20 px que
  se monta unos 20 px sobre el color. Nunca hay una hoja dentro de otra.
- *Tarjeta flotante:* solo en Inicio, la tarjeta del total pendiente queda a caballo entre
  la cabecera y la hoja, con radio de 16 px y la sombra muy suave. Lleva la carita feliz (sin
  deuda) o triste (con deuda) junto al monto.
- *Ingreso:* cabecera turquesa alta (40 % de la pantalla; 34 % en pantallas de menos de
  700 px) con el logo vertical blanco al centro, y el formulario en una hoja blanca que sube
  sobre ella. Con el teclado abierto la cabecera se reduce a la barra de estado.
- En Flutter se arma con `CabeceraMarca`, `HojaBlanca` y `TarjetaFlotante`
  (`lib/core/widgets/componentes.dart`), o con `CuerpoAsync(cabecera: …)`.

**Pantalla de carga (app móvil).** El splash nativo de Android y de la web es turquesa
completo con el ícono blanco al centro (Android 12 o superior solo admite color de fondo e
ícono). Después sigue la pantalla de carga de Flutter con el mismo fondo, el ícono en el
mismo lugar y tamaño (112 dp) y «Almira» debajo, mientras se recupera la sesión. Las barras
del sistema van en el mismo turquesa y la ventana de Android también, para que no aparezca
una franja blanca.

**Fichas de datos.** Rótulo de 13 px en `textSecondary` arriba y el valor de 15 px debajo,
a todo el ancho (no en dos columnas). Solo los montos van en filas con el valor alineado a
la derecha. Los grupos se separan con 24 px o con una línea fina, no con cajas.

**Filas de lista.** Nombre a la izquierda en 15 px 500, línea secundaria en 13 px
`textSecondary`, monto a la derecha y flecha. Mínimo 56 px de alto, separadas por una línea
de 1 px.

**Accesos rápidos de Inicio.** Una fila de cuatro círculos `highlight` de 56 px con el ícono
`primary` de 24 px y la etiqueta debajo, centrada, en hasta dos líneas.

**Plazos y vencimientos.** Van en una línea de texto de 13 px en `textSecondary`: «Vence el
30 de noviembre», «Respuesta hasta el 27 de noviembre». Si ya venció, esa línea va en
`dangerText`, sin píldora ni reloj. Las insignias quedan para estados reales: En atención,
Resuelto, Vencida y Pagada.

**Pestañas.** Donde una pantalla tiene dos vistas (Estado de cuenta / Historial de pagos) se
usan pestañas con subrayado `primary`, no un control segmentado. Con letra grande se
desplazan en vez de cortarse.

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

**Panel web.** Densidad compacta: el Panel municipal entra completo, sin scroll, en una
laptop con área visible de 1536 × 730 px (1920 × 1080 al 125 %).
- *Barra lateral:* blanca, de 248 px, con borde derecho de 1 px y relleno de 16 × 12 px.
  Arriba van el logo de 28 px, "Almira" y el nombre de la municipalidad (viene de los
  datos). Cada módulo mide 36 px; el activo va con fondo `highlight` y texto
  `primaryPressed` 600. El contador va en círculo `primary` con texto blanco. Abajo va el
  usuario, con avatar de 32 px.
- *Contenido:* fondo `panelBackground`, márgenes de 16 × 20 px y separación de 12 px entre
  tarjetas. Las tarjetas son blancas, con borde, radio de 12 px, relleno de 14 × 16 px y
  separación interna de 8 px. El subtítulo de la página y de cada tarjeta va en la misma
  línea que el título; si no cabe, pasa abajo.
- *Indicadores:* relleno de 10 × 16 px, separación de 2 px y barra de avance de 4 px; no
  pasan de 96 px de alto.
- *Gráficos:* barras verticales de 120 px de alto (cifra incluida) y barras horizontales
  en filas de 24 px, con riel de 10 px.
- *Requiere tu decisión:* filas de 40 px con caja de ícono de 32 px.
- *Cómo aprende la municipalidad y ruta del incidente:* una fila de 5 celdas con relleno
  de 4 × 14 px.
- *Tablas:* sin bordes verticales, celdas con relleno de 8 × 12 px, encabezado en
  mayúsculas `textSecondary` y filas separadas por 1 px. La fila seleccionada lleva fondo
  `subtle`.
- *Mapa "Vista del vecino":* 380 × 300 px.
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
