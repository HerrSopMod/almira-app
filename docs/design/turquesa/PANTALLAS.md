# Pantallas: qué imagen seguir en cada una

- **Maqueta** = imagen en `turquesa/movil` o `turquesa/web`, con su HTML en `turquesa/fuentes`.
- **Stitch N** = `docs/design/stitch_almira_gesti_n_tributaria_municipal/N._…/screen.png`,
  adaptada con los textos de `prototipo/TEXTOS.md` y las reglas de `LEEME.md`.

En todas las pantallas se mantienen la ruta y la lógica actuales, salvo donde se indica
otra cosa.

## Cambios de recorrido frente al prototipo rojo

1. **Pestañas:** Inicio, Pagar, Reclamos, Obras y Asistente, en ese orden. La pestaña
   "Mi cuenta" pasa a llamarse **Pagar** y conserva su ruta (`(tabs)/cuenta`).
2. **Ingreso:** la app abre en Ingreso (Stitch 1), con Google, correo o celular (Supabase
   Auth). Después:
   - Con cualquier método: Elegir municipalidad (Paso 2 de 5) → Vincular códigos (Paso 3) →
     Confirmar celular (Paso 4, opcional, para WhatsApp) → Consentimiento (Paso 5) → Inicio.
     Con celular, el número ya queda confirmado.
   - Nadie entra a Inicio sin aceptar el consentimiento. Lo aceptado se guarda en la
     cuenta; en los siguientes ingresos se pasa directo a Inicio.
   - Sin Supabase configurado, los tres métodos se simulan con datos de ejemplo y siguen el
     mismo recorrido. El código de ejemplo sigue siendo `482175`.
   - El selector de municipalidad sale de Entrada y pasa a Stitch 4. Entrada (01) ya no se
     abre al iniciar la app.
3. **Accesos de Inicio:** se quita la cuadrícula de 6 accesos. Avisos queda en la campana
   de la barra superior y Mi perfil en el avatar; las otras 4 ya son pestañas.
4. **Asistente:** se llama "Asistente" (no "Asistente con IA") mientras responda con
   reglas fijas.
5. **Detalle del aviso:** el botón "Ir a Mi cuenta" pasa a ser "Ir a pagar".

## App móvil

> **Texto mínimo (manda sobre TEXTOS.md):** ninguna pantalla lleva el pie «Prototipo académico · Datos ficticios», avisos de «datos de ejemplo» ni notas obvias (por ejemplo «Usa los datos con los que figuras en el padrón»). Los títulos van centrados.

| # | Pantalla | Ruta actual | Seguir | Notas de adaptación |
| --- | --- | --- | --- | --- |
| 01 | Entrada | `(auth)/entrada` | Maqueta `01-entrada` | Sin selector de municipalidad. "No tengo cuenta ni smartphone propio" lleva a 23. |
| 02a | Ingresa a tu cuenta | `(auth)/ingreso` | Stitch 1 | Barra superior blanca "Paso 1 de 3", sin flecha atrás ni cabecera de color. Botón Google, divisor "o con tu correo" / "o con tu celular" y control segmentado Correo / Celular. Correo: correo, contraseña (mínimo 8) con botón para verla, "Ingresar" y "¿No tienes cuenta? Créala". Celular (+51, 9 dígitos): "Recibir código por SMS" y, después, el código de 6 dígitos y "Verificar código". Abajo: "Datos de ejemplo…" (solo sin Supabase), "Antes de entrar te pediremos tu consentimiento para usar tus datos.", el botón terciario "No tengo cuenta ni smartphone propio" (lleva a 23) y "Prototipo académico · Datos ficticios". Sin RENIEC, teléfono ni "términos de servicio". |
| 02c | Vincula tus códigos | `(auth)/vincular-codigos` | Stitch 3 | Después de 02d. Código de contribuyente (o de predio) más DNI, validados contra el padrón; se pueden agregar varios. "Continuar" se habilita con al menos uno. Sin "biométrica". |
| 02d | Elige tu municipalidad | `(auth)/municipalidad` | Stitch 4 | Primer paso tras autenticarse. Lista de municipalidades desde los datos. Buscador y chips de zona solo si hay más de 5. Encabezado "Paso 2 de 5". |
| 02e | Confirma tu celular | `(auth)/celular` | Stitch 2 | Paso 4 de 5, opcional ("Ahora no"). Celular +51 y código SMS de 6 dígitos. Sin celular confirmado, WhatsApp y SMS quedan apagados en 03. |
| 03 | Consentimiento | `(auth)/consentimiento` | Maqueta `03-consentimiento` | Encabezado "Paso 5 de 5". Último paso del ingreso: "Aceptar y entrar" guarda el consentimiento y recién ahí abre Inicio. |
| 04 | Inicio | `(tabs)/inicio` | Stitch 5 | Saludo "Hola, Rosa", municipalidad desde los datos. Destacado: deuda total S/ 120.50, próximo vencimiento, barra En mora / Por vencer y botón "Ver detalle y pagar". Debajo, fila de aviso ("Tu arbitrio vence pronto"), "Tributos registrados" (filas de Stitch 5) y "En tu distrito" (obra con avance y reclamo con plazo). Sin "Pronto pago trimestral" ni otro texto de Stitch. |
| 05 | Pagar (Mi cuenta municipal) | `(tabs)/cuenta` | Stitch 7, parte superior | Título "Mi cuenta municipal". Lista "Tributos pendientes" con casilla (todas marcadas al entrar): Multa administrativa S/ 40.00 (En mora) y Arbitrios S/ 80.50 (Por vencer). "Total seleccionado" y botón "Pagar S/ 120.50", que cambia al desmarcar. Debajo, "Pagos y constancias". Nota "Beneficio vigente: consulta con el asistente". |
| 06 | Detalle de la deuda | `(tabs)/cuenta/deuda/[id]` | Stitch 6 | Filas clave–valor, insignia de estado y Destacado "En palabras simples". Botones: Pagar S/ 80.50 / Simular cuotas / Preguntar al asistente. Enlace "¿Crees que este cobro es incorrecto? Reclámalo". Sin "verificado y encriptado". |
| 07 | Confirma tu pago | `pago/confirmar` | Stitch 7, parte inferior | Resumen de lo seleccionado + "¿Cómo quieres pagar?" con 4 opciones de radio (Yape, Plin, Tarjeta de débito o crédito, Banca móvil o agente). Nota de los avisos detenidos por 48 h. "Pago simulado…". Si la municipalidad tiene portal de pago (dato `url_pago`), se quitan las opciones y el botón pasa a "Ir al portal de pago": lleva al portal oficial, con la nota "Almira no procesa el pago ni lo confirma". Sin portal y con Supabase, el botón queda apagado. Sin ISO, firma digital ni "Sin comisiones". |
| 08 | Constancia de pago | `pago/constancia` | Maqueta `08-constancia-de-pago` | |
| 09 | Recordatorios | `(tabs)/inicio/recordatorios` | Stitch 8 | Destacado "Almira te avisa; no ejecuta cobranzas coactivas". "Mis avisos", escalera de 3 pasos con "Estás aquí", canales con **interruptores** (no radio, porque se pueden elegir varios) y la nota de los topes. Enlace "Ver cómo llegan por WhatsApp y SMS". |
| 10 | Detalle del aviso | `avisos/[id]` | Maqueta `10-detalle-del-aviso` | |
| 11 | Cómo llegan los avisos | `avisos/como-llegan` | Maqueta `11-como-llegan-los-avisos` | El control segmentado cambia entre la vista de WhatsApp y la de SMS. |
| 12 | Asistente | `(tabs)/asistente` | Stitch 9 | Rótulo "ASISTENTE DE ALMIRA". Preguntas sugeridas del prototipo, conversación con burbujas, botones "Simular cuotas" y "Hablar con una persona", y nota "El asistente orienta, no decide. Prototipo: respuestas fijas de ejemplo." Sin "Atención virtual SAT" ni "Encriptación ciudadana". El simulador va en la pantalla 13, no incrustado. |
| 13 | Simulación de cuotas | `simulacion-cuotas` | Maqueta `13-simulacion-de-cuotas` | |
| 14 | Atención humana | `atencion-humana` | Maqueta `14-atencion-humana` | |
| 15 | Reclamos | `(tabs)/reclamos` | Stitch 10 | Botón "Nuevo reclamo con foto" arriba. Tarjetas con código, título, insignia, miniatura de la foto simulada, área y plazo. Nota del área y el plazo. Al final, "¿Necesitas ayuda? Hablar con una persona" (lleva a 14), sin teléfono. Sin "Geo-validación". |
| 16 | Nuevo reclamo | `reclamo/nuevo` | Maqueta `16-nuevo-reclamo` | Foto con la cámara ("Tomar foto", "Tomar otra foto") y botón "Usar mi ubicación" con el GPS, ambos con permiso. Minimapa real con un marcador: el punto del GPS o, si no lo hay, el del predio de ejemplo (ver MAPA.md). Con Supabase la foto se sube al bucket `evidencias` y el reclamo se guarda con la dirección y el punto del GPS. No digas que la foto se envía como evidencia. |
| 17 | Envío al área | `reclamo/envio` | Maqueta `17-envio-al-area` | |
| 18 | Seguimiento | `(tabs)/reclamos/[id]` | Maqueta `18-seguimiento` | La fila del plazo dice "Quedan 3 de 10 días" (no "3 de 10 días") y la barra muestra el tiempo que ya pasó (7 de 10). |
| 19 | Obras (mapa) | `(tabs)/obras` | Maqueta `19-mapa-de-obras` | Mapa real (MAPA.md). Al tocar un marcador se resalta su tarjeta y la lista se desplaza hasta ella. Chips para filtrar. |
| 20 | Detalle de la obra | `(tabs)/obras/[id]` | Maqueta `20-detalle-de-la-obra` | El ícono de mapa y "Ver en el mapa" vuelven a 19 con esa obra seleccionada. |
| 21 | Mi perfil | `(tabs)/inicio/perfil` | Maqueta `21-mi-perfil` | "Mi municipalidad" abre 02d. "Texto más grande" mantiene `largeTextScale`. |
| 22 | Privacidad y mis datos | `privacidad` | Maqueta `22-privacidad-y-mis-datos` | |
| 23 | Sin smartphone | `sin-smartphone` | Maqueta `23-sin-smartphone` | Se abre sin sesión desde el ingreso (02a), y también desde Mi perfil y Atención humana. |

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
