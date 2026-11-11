# Cambios

## 1.0.0 · Migración a Flutter y rediseño

App de vecinos reescrita en Flutter, con el mismo backend de Supabase. La app de Expo (`apps/mobile`) queda como referencia.

### General

- Tema Material 3 centralizado: fondo blanco, turquesa `#0B7F86` para acciones y encabezados, y rojo, ámbar y verde solo para estados, siempre con texto e ícono.
- Tipografía Inter incluida en la app. Una sola familia de íconos, redondeada.
- Logo nuevo (casa con globo de diálogo) en el ingreso y en el ícono de la app.
- Encabezado turquesa que se extiende detrás de la barra del sistema, con íconos claros. El ingreso, de fondo blanco, usa íconos oscuros. La app dibuja de borde a borde y respeta las áreas seguras.
- Barra inferior con cinco destinos, indicador activo y animación breve. Cada pestaña conserva su estado. Se oculta con el teclado abierto.
- Estados de carga, vacío, error y sin conexión en todas las pantallas con datos. Un error nunca se muestra como «S/ 0.00» ni como lista vacía.
- Fechas, vencimientos y plazos con la fecha del teléfono. Antes usaban una fecha fija de ejemplo.
- Montos en soles con punto decimal y coma de millar.
- Respeta el tamaño de letra del sistema (hasta 1.6×) y «reducir movimiento».

### Ingreso y privacidad

- De cinco pasos a dos, una sola vez: municipalidad y código, y privacidad. En las siguientes aperturas entra directo a Inicio.
- El código de contribuyente se puede vincular después, desde Mi perfil.
- Privacidad separa lo necesario para el servicio de lo opcional. Las tres preferencias opcionales empiezan apagadas y «Continuar» no activa ninguna.
- «Guardar mis consultas al asistente» ahora hace lo que dice: apagado, la conversación no se guarda.
- Se quitó «Máximo 1 por día y 3 por semana»: el backend no aplica ese límite.

### Inicio

- Tarjeta única con el total pendiente, la cantidad de obligaciones y el próximo vencimiento. El total sale de la suma de las deudas.
- La barra de porcentajes se cambió por dos insignias: vencido y por vencer, con su monto.
- Se quitó el aviso que repetía la fecha de vencimiento.
- Sin deuda: «Estás al día» y acceso al historial. Sin código vinculado: invitación a vincularlo.

### Pagar

- Filtros Pendientes, Vencidos y Pagados. Detalle con importe, intereses, total y fecha límite.
- Una deuda «vigente» con fecha pasada se muestra vencida.
- El pago abre el portal de la municipalidad. Ya no hay pago ni constancia simulados.

### Reclamos

- Formulario en una pantalla: foto, asunto, descripción, categoría y ubicación, con límites visibles.
- **Foto real:** de la cámara o la galería, reducida antes de subir, con miniatura, cambiar y quitar. Se guarda en Storage y el seguimiento la muestra, ampliable. Antes era un dibujo fijo.
- **Mapa:** selector con pin que se ubica moviendo el mapa o con el GPS. Sin permiso de ubicación se sigue a mano. El seguimiento muestra el punto guardado.
- **Plazo corregido:** ya no aparece «Quedan 16 de 10 días». Se calcula en días hábiles; si los datos no cuadran, «Plazo por confirmar».
- El asunto se valida: no acepta textos como «Jjkkk».
- La cronología solo marca etapas que los datos respaldan.
- Si el envío falla, el formulario conserva todo y ofrece reintentar. Un reintento no vuelve a subir la foto.

### Obras

- Mapa y lista comparten el mismo filtro. Tocar un marcador resalta su tarjeta; «Ver en el mapa» centra la obra.
- Botón para ver solo la lista.
- «Avance físico» va rotulado y separado del presupuesto gastado.

### Mi perfil

- Cabecera compacta. Opciones en tres grupos, sin separadores por fila.
- No muestra DNI ni teléfono.

### Asistente

- Responde con reglas fijas sobre los datos de la cuenta y lo dice en pantalla. Cada respuesta lleva a la pantalla donde se resuelve.

## Pruebas ejecutadas

| Prueba | Resultado |
| --- | --- |
| `flutter analyze` | Sin observaciones |
| `flutter test` | 31 pruebas aprobadas: formato, plazos, deuda, validaciones, cronología, rutas, asistente, primer ingreso, segunda apertura, pestañas, texto al doble de tamaño y persistencia de un reclamo |
| `flutter build web --release` | Compila. Las capturas de `docs/capturas` salen de esta compilación, en modo demostración, a 412 × 915 |
| Recorrido manual en la compilación web | Foto adjunta con miniatura, categoría sugerida, pin elegido en el mapa y seguimiento con foto, mapa y plazo |
| `flutter build apk --release` | Ver nota |
| `integration_test/flujo_demo_test.dart` | Escrita, **no ejecutada**: no había teléfono ni emulador |

## Pendiente de verificar

- **En un teléfono Android:** la barra del sistema, la cámara, el permiso de ubicación, el teclado y los gestos. La compilación web no los ejercita.
- **Con Supabase real:** ingreso, lectura de datos, subida de la foto y vínculo del código. Falta `env.json` con la URL y la clave anon.
- **Logo:** la imagen recibida mide 310 × 282 px. Se ve bien en pantalla, pero el ícono de la app necesita una versión de 1024 px o vectorial para quedar nítido.
