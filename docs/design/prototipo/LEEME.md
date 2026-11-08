# Prototipo de Almira (Figma)

Esta carpeta es la fuente de verdad del diseño. Reemplaza a las pantallas de Stitch en `docs/design/stitch_almira_gesti_n_tributaria_municipal`.

- `general/`: portada, guía de estilos y mapa de flujos.
- `movil/`: las 23 pantallas de la app del vecino, en orden (390 px de ancho, exportadas al doble).
- `web/`: el ingreso y las 8 páginas del panel municipal (1440 px de ancho).
- `TEXTOS.md`: los textos de cada pantalla, extraídos del PDF. Cópialos tal cual; si el orden no se entiende, manda la imagen.

Todo usa datos ficticios. El pago, el SMS, el QR y el asistente son simulados.

## Guía de estilos

### Colores

| Nombre | Hex | Uso |
| --- | --- | --- |
| Encabezados | `#800404` | Barra superior de la app y barra lateral del panel |
| Primario | `#C00000` | Botones primarios, chips activos, pestaña activa |
| Barra secundaria | `#F4A6A6` | Barras de gráficos secundarias |
| Fondo rosado | `#F7ECEC` | Botón secundario, tarjetas suaves, avisos informativos |
| Deuda pendiente | `#FFFFCC` | Tarjeta de deuda pendiente y chip «Por vencer» |
| Gris de apoyo | `#E8E8E8` | Bloques neutros |
| Superficie | `#FFFFFF` | Fondo y tarjetas |
| Texto | `#2B2B2B` | Texto principal |
| Texto secundario | `#595959` | Texto de apoyo |
| Líneas | `#808080` | Bordes y separadores |
| Pagado | `#2E8B57` | Estado pagado o correcto |
| Pagado claro | `#E2F3E8` | Fondo del estado pagado |
| Aviso 3 | `#5B1428` | Aviso previo a cobranza coactiva |
| Aviso 2 | `#9A5563` | Aviso de mora |
| Aviso 1 | `#E9C1C6` | Recordatorio amable |

Los tonos vino (Aviso 1 a 3) se reservan para la escalera de avisos.

### Tipografía

- Poppins Bold: montos y marca.
- Poppins SemiBold: títulos.
- Inter SemiBold 14: etiquetas y botones.
- Inter Regular 14: texto de lectura.
- Inter Regular 12: ayudas y pies.

### Componentes

Botón primario, botón secundario (fondo rosado y texto primario), botón de línea, chip activo, chip, insignias «Pagada», «Por vencer», «En mora» e «Información», interruptor, casilla, radio y la escalera de tres avisos.
