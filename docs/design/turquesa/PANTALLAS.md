# Pantallas: qué imagen seguir en cada una

- **Maqueta** = imagen en `turquesa/movil` o `turquesa/web`, con su HTML en `turquesa/fuentes`.
- **Stitch N** = `docs/design/stitch_almira_gesti_n_tributaria_municipal/N._…/screen.png`,
  adaptada con los textos de `prototipo/TEXTOS.md` y las reglas de `LEEME.md`.

En todas las pantallas se mantienen la ruta y la lógica actuales, salvo donde se indica
otra cosa.

## Cambios de recorrido frente al prototipo rojo

1. **Pestañas:** Inicio, Pagar, Reclamos, Obras y Asistente, en ese orden. La pestaña
   "Mi cuenta" pasa a llamarse **Pagar** y conserva su ruta (`(tabs)/cuenta`).
2. **Ingreso:** Entrada (01) → Ingreso (Stitch 1) → Código SMS (Stitch 2) → Vincular DNI
   (Stitch 3, solo si entró con Google) → Elegir municipalidad (Stitch 4) →
   Consentimiento (03) → Inicio.
   - El selector de municipalidad sale de Entrada y pasa a Stitch 4.
   - Mientras Supabase no esté conectado, "Continuar con Google" se simula: lleva a
     Vincular DNI con datos de ejemplo. El código de ejemplo sigue siendo `482175`.
3. **Accesos de Inicio:** se quita la cuadrícula de 6 accesos. Avisos queda en la campana
   de la barra superior y Mi perfil en el avatar; las otras 4 ya son pestañas.
4. **Asistente:** se llama "Asistente" (no "Asistente con IA") mientras responda con
   reglas fijas.
5. **Detalle del aviso:** el botón "Ir a Mi cuenta" pasa a ser "Ir a pagar".

## App móvil

| # | Pantalla | Ruta actual | Seguir | Notas de adaptación |
| --- | --- | --- | --- | --- |
| 01 | Entrada | `(auth)/entrada` | Maqueta `01-entrada` | Sin selector de municipalidad. "No tengo cuenta ni smartphone propio" lleva a 23. |
| 02a | Ingresa a tu cuenta | `(auth)/ingreso` | Stitch 1 | Botón Google + "o con tu DNI" + campo DNI o carné (8 a 12) + "Recibir código por SMS". Sin RENIEC ni teléfono. Abajo: "Datos de ejemplo…" y "Prototipo académico · Datos ficticios". Encabezado "Paso 1 de 3". |
| 02b | Ingresa el código | nueva `(auth)/codigo` | Stitch 2 | 6 casillas, "Lo enviamos por SMS al +51 9•• ••• 417", "Reenviar código", "Cambiar DNI". Usa el teclado del sistema, no el teclado dibujado. Código de ejemplo `482175`. |
| 02c | Vincula tu DNI | nueva `(auth)/vincular-dni` | Stitch 3 | Solo tras Google. Destacado: "Te enviaremos un código SMS al celular registrado en el padrón municipal." Sin "biométrica". Nota de la Ley N.° 29733 sin más afirmaciones. |
| 02d | Elige tu municipalidad | nueva `(auth)/municipalidad` | Stitch 4 | Lista de municipalidades desde los datos (hoy solo Lince habilitada). Buscador y chips de zona solo si hay más de 5. Nota "Podrás cambiarla desde Mi perfil". Encabezado "Paso 2 de 3". |
| 03 | Consentimiento | `(auth)/consentimiento` | Maqueta `03-consentimiento` | Encabezado "Paso 3 de 3". |
| 04 | Inicio | `(tabs)/inicio` | Stitch 5 | Saludo "Hola, Rosa", municipalidad desde los datos. Destacado: deuda total S/ 120.50, próximo vencimiento, barra En mora / Por vencer y botón "Ver detalle y pagar". Debajo, fila de aviso ("Tu arbitrio vence pronto"), "Tributos registrados" (filas de Stitch 5) y "En tu distrito" (obra con avance y reclamo con plazo). Sin "Pronto pago trimestral" ni otro texto de Stitch. |
| 05 | Pagar (Mi cuenta municipal) | `(tabs)/cuenta` | Stitch 7, parte superior | Título "Mi cuenta municipal". Lista "Tributos pendientes" con casilla (todas marcadas al entrar): Multa administrativa S/ 40.00 (En mora) y Arbitrios S/ 80.50 (Por vencer). "Total seleccionado" y botón "Pagar S/ 120.50", que cambia al desmarcar. Debajo, "Pagos y constancias". Nota "Beneficio vigente: consulta con el asistente". |
| 06 | Detalle de la deuda | `(tabs)/cuenta/deuda/[id]` | Stitch 6 | Filas clave–valor, insignia de estado y Destacado "En palabras simples". Botones: Pagar S/ 80.50 / Simular cuotas / Preguntar al asistente. Enlace "¿Crees que este cobro es incorrecto? Reclámalo". Sin "verificado y encriptado". |
| 07 | Confirma tu pago | `pago/confirmar` | Stitch 7, parte inferior | Resumen de lo seleccionado + "¿Cómo quieres pagar?" con 4 opciones de radio (Yape, Plin, Tarjeta de débito o crédito, Banca móvil o agente). Nota de los avisos detenidos por 48 h. "Pago simulado…". Sin ISO, firma digital ni "Sin comisiones". |
| 08 | Constancia de pago | `pago/constancia` | Maqueta `08-constancia-de-pago` | |
| 09 | Recordatorios | `(tabs)/inicio/recordatorios` | Stitch 8 | Destacado "Almira te avisa; no ejecuta cobranzas coactivas". "Mis avisos", escalera de 3 pasos con "Estás aquí", canales con **interruptores** (no radio, porque se pueden elegir varios) y la nota de los topes. Enlace "Ver cómo llegan por WhatsApp y SMS". |
| 10 | Detalle del aviso | `avisos/[id]` | Maqueta `10-detalle-del-aviso` | |
| 11 | Cómo llegan los avisos | `avisos/como-llegan` | Maqueta `11-como-llegan-los-avisos` | El control segmentado cambia entre la vista de WhatsApp y la de SMS. |
| 12 | Asistente | `(tabs)/asistente` | Stitch 9 | Rótulo "ASISTENTE DE ALMIRA". Preguntas sugeridas del prototipo, conversación con burbujas, botones "Simular cuotas" y "Hablar con una persona", y nota "El asistente orienta, no decide. Prototipo: respuestas fijas de ejemplo." Sin "Atención virtual SAT" ni "Encriptación ciudadana". El simulador va en la pantalla 13, no incrustado. |
| 13 | Simulación de cuotas | `simulacion-cuotas` | Maqueta `13-simulacion-de-cuotas` | |
| 14 | Atención humana | `atencion-humana` | Maqueta `14-atencion-humana` | |
| 15 | Reclamos | `(tabs)/reclamos` | Stitch 10 | Botón "Nuevo reclamo con foto" arriba. Tarjetas con código, título, insignia, miniatura de la foto simulada, área y plazo. Nota del área y el plazo. Al final, "¿Necesitas ayuda? Hablar con una persona" (lleva a 14), sin teléfono. Sin "Geo-validación". |
| 16 | Nuevo reclamo | `reclamo/nuevo` | Maqueta `16-nuevo-reclamo` | Minimapa real con un marcador (ver MAPA.md). La ubicación sigue simulada. |
| 17 | Envío al área | `reclamo/envio` | Maqueta `17-envio-al-area` | |
| 18 | Seguimiento | `(tabs)/reclamos/[id]` | Maqueta `18-seguimiento` | |
| 19 | Obras (mapa) | `(tabs)/obras` | Maqueta `19-mapa-de-obras` | Mapa real (MAPA.md). Al tocar un marcador se resalta su tarjeta y la lista se desplaza hasta ella. Chips para filtrar. |
| 20 | Detalle de la obra | `(tabs)/obras/[id]` | Maqueta `20-detalle-de-la-obra` | El ícono de mapa y "Ver en el mapa" vuelven a 19 con esa obra seleccionada. |
| 21 | Mi perfil | `(tabs)/inicio/perfil` | Maqueta `21-mi-perfil` | "Mi municipalidad" abre 02d. "Texto más grande" mantiene `largeTextScale`. |
| 22 | Privacidad y mis datos | `privacidad` | Maqueta `22-privacidad-y-mis-datos` | |
| 23 | Sin smartphone | `sin-smartphone` | Maqueta `23-sin-smartphone` | |

## Panel web

| # | Página | Archivo actual | Seguir |
| --- | --- | --- | --- |
| web-01 | Ingreso al panel | `paginas/Ingreso.tsx` | Maqueta `web-01-ingreso-al-panel` |
| web-02 | Panel municipal | `paginas/PanelMunicipal.tsx` | Maqueta `web-02-panel-municipal` |
| web-03 | Recaudación y pagos | `paginas/Recaudacion.tsx` | Maqueta `web-03-recaudacion-y-pagos` |
| web-04 | Avisos y respuestas | `paginas/Avisos.tsx` | Maqueta `web-04-avisos-y-respuestas` |
| web-05 | Reclamos por área | `paginas/Reclamos.tsx` | Maqueta `web-05-reclamos-por-area` |
| web-06 | Obras publicadas | `paginas/Obras.tsx` | Maqueta `web-06-obras-publicadas`, con el mapa real "Vista del vecino" (MAPA.md) |
| web-07 | Atención humana | `paginas/AtencionHumana.tsx` | Maqueta `web-07-atencion-humana` |
| web-08 | Alertas y auditoría | `paginas/Alertas.tsx` | Maqueta `web-08-alertas-y-auditoria` |
| web-09 | Datos y accesos | `paginas/DatosAccesos.tsx` | Maqueta `web-09-datos-y-accesos` |

En el panel se mantienen el comportamiento en memoria (`estado.tsx`), los contadores
del menú y las acciones actuales (Tomar, +5 % de avance, Publicada, Usar variante B…).
