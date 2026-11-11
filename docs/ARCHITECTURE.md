# Arquitectura de Almira

Almira permite a vecinos de distintas municipalidades de Lima pagar tributos y reclamar con evidencia. Almira es la marca fija; la municipalidad es un dato que el vecino elige.

**Estado actual:** prototipo con datos de ejemplo. La app de vecinos autentica con Supabase Auth (Google, correo y celular con código SMS) si tiene las variables de entorno; si no, simula el ingreso. Los datos que se ven siguen siendo de ejemplo: no se leen tablas de Supabase, no hay pasarela de pago, la foto del reclamo no se sube y solo los recordatorios por SMS tienen envío real (Edge Function con Twilio). El panel web no tiene autenticación real.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `apps/almira_flutter` | App de vecinos en Flutter y Dart. Es el cliente móvil vigente: ver su `README.md` |
| `apps/mobile` | App de vecinos anterior, con Expo y React Native. Queda como referencia |
| `apps/web` | Panel municipal con Vite, React y TypeScript |
| `packages/shared` | Tokens de diseño, tipos, formato y datos de ejemplo |
| `supabase` | Migraciones, RLS, datos de semilla y Edge Function |
| `docs/design` | Diseños de Stitch y `DESIGN.md`, solo como referencia |

Las apps importan `@almira/shared` directamente desde su código TypeScript, sin paso de compilación.

## Rutas móviles

| Pantalla | Ruta | Archivo |
| --- | --- | --- |
| Entrada (01) | `/entrada` | `app/(auth)/entrada.tsx` |
| Ingresa a tu cuenta (02a) | `/ingreso` | `app/(auth)/ingreso.tsx` |
| Ingresa el código (02b) | `/codigo` | `app/(auth)/codigo.tsx` |
| Vincula tu DNI (02c) | `/vincular-dni` | `app/(auth)/vincular-dni.tsx` |
| Elige tu municipalidad (02d) | `/municipalidad` (desde Mi perfil, `/municipalidad?modo=cambio`) | `app/(auth)/municipalidad.tsx` |
| Tus datos, tus reglas (03) | `/consentimiento` | `app/(auth)/consentimiento.tsx` |
| Sin smartphone (23) | `/sin-smartphone` | `app/sin-smartphone.tsx` |
| Privacidad y mis datos (22) | `/privacidad` | `app/privacidad.tsx` |
| Inicio (04) | `/inicio` | `app/(tabs)/inicio/index.tsx` |
| Recordatorios (09) | `/inicio/recordatorios` | `app/(tabs)/inicio/recordatorios.tsx` |
| Mi perfil (21) | `/inicio/perfil` | `app/(tabs)/inicio/perfil.tsx` |
| Detalle del aviso (10) | `/avisos/[id]` | `app/avisos/[id].tsx` |
| Cómo llegan los avisos (11) | `/avisos/como-llegan` | `app/avisos/como-llegan.tsx` |
| Atención humana (14) | `/atencion-humana` | `app/atencion-humana.tsx` |
| Pagar · Mi cuenta municipal (05) | `/cuenta` | `app/(tabs)/cuenta/index.tsx` |
| Detalle de la deuda (06) | `/cuenta/deuda/[id]` | `app/(tabs)/cuenta/deuda/[id].tsx` |
| Confirma tu pago (07) | `/pago/confirmar` | `app/pago/confirmar.tsx` |
| Constancia de pago (08) | `/pago/constancia` | `app/pago/constancia.tsx` |
| Asistente (12) | `/asistente` | `app/(tabs)/asistente.tsx` |
| Simulación de cuotas (13) | `/simulacion-cuotas` | `app/simulacion-cuotas.tsx` |
| Reclamos (15) | `/reclamos` | `app/(tabs)/reclamos/index.tsx` |
| Seguimiento (18) | `/reclamos/[id]` | `app/(tabs)/reclamos/[id].tsx` |
| Nuevo reclamo (16) | `/reclamo/nuevo` | `app/reclamo/nuevo.tsx` |
| Envío al área (17) | `/reclamo/envio` | `app/reclamo/envio.tsx` |
| Mapa de obras (19) | `/obras` | `app/(tabs)/obras/index.tsx` |
| Detalle de la obra (20) | `/obras/[id]` | `app/(tabs)/obras/[id].tsx` |

Flujo de ingreso:

- La app abre en Ingresa a tu cuenta (`app/index.tsx` redirige a `/ingreso`).
- Con Google o correo: Ingresa a tu cuenta, Vincula tu DNI, Ingresa el código, Elige tu municipalidad, Tus datos tus reglas, Inicio.
- Con celular: Ingresa a tu cuenta (ahí se pide y verifica el código SMS), Elige tu municipalidad, Tus datos tus reglas, Inicio.
- Nadie llega a Inicio sin aceptar el consentimiento (Ley N.° 29733). `app/_layout.tsx` pone las pestañas y las demás pantallas de la app dentro de `Stack.Protected` con `consentimientoAceptado`; si se abre una de ellas sin haberlo aceptado, vuelve al ingreso. El ingreso, Privacidad y mis datos y Sin smartphone quedan abiertos.
- Vincula tu DNI, Ingresa el código y Elige tu municipalidad vuelven al ingreso si el vecino no se autenticó.
- Al aceptar el consentimiento se cierran las pantallas de ingreso: "volver" ya no regresa a ellas.
- En el ingreso, "No tengo cuenta ni smartphone propio" lleva a Sin smartphone, que se abre sin sesión; su flecha vuelve al ingreso. También se abre desde Atención humana y Mi perfil.
- Entrada (01) sigue en `app/(auth)/entrada.tsx`, pero ya no se abre al iniciar.

`src/auth.tsx` usa Supabase Auth: `signInWithOAuth` con Google (en el teléfono, con `expo-web-browser`), `signInWithPassword` y `signUp` con correo, `signInWithOtp` y `verifyOtp` con celular (+51), y `signOut` al cerrar sesión. La sesión se guarda con AsyncStorage. Al aparecer la sesión, el ingreso sigue el recorrido de `irTrasIngreso` (`src/recorrido.ts`), que elige el paso según el proveedor de la cuenta (`google`, `email` o `phone`).

Al aceptar el consentimiento, `src/sesion.tsx` guarda en `user_metadata.almira` de la cuenta la municipalidad elegida, los permisos y la fecha (`DatosIngreso`), sin teléfono ni DNI. Si la cuenta ya lo tiene, el siguiente ingreso pasa directo a Inicio. Los cambios de municipalidad (desde Mi perfil) y de permisos (desde Privacidad y mis datos) actualizan esos datos. Si entra otra cuenta, no hereda lo elegido por la anterior.

La vinculación del DNI y el SMS al celular del padrón (pantallas 02c y 02b) siguen simulados: no se consulta ningún padrón ni se envía ese SMS. El documento viene lleno con el DNI de ejemplo de Rosa y acepta de 8 a 12 letras o números (`documentoValido`). El código viene lleno con `482175` y sirve cualquier código de 6 dígitos (`codigoValido`). "Reenviar código" solo avisa que el reenvío es simulado y "Cambiar DNI" vuelve a Vincula tu DNI.

Sin `EXPO_PUBLIC_SUPABASE_URL` y `EXPO_PUBLIC_SUPABASE_ANON_KEY` (`apps/mobile/.env.local`, ver `.env.example`), la app sigue funcionando con los datos de ejemplo: Google, correo y celular se simulan (no se abre Google ni se envía nada; el código de celular viene lleno con `482175`), siguen el mismo recorrido y todo vive en memoria hasta cerrar la app. La pantalla lo dice en la nota "Datos de ejemplo…".

Elige tu municipalidad muestra las municipalidades activas tal como están en los datos (`municipalidades` de `datos-ejemplo.ts`). El buscador y los chips de zona solo aparecen si hay más de 5. La elegida se guarda en la sesión al tocar "Continuar". Desde Mi perfil, "Mi municipalidad" la abre con `modo=cambio`: sin "Paso 2 de 3" ni la nota, con el botón "Guardar", y vuelve al perfil. Solo cambia la municipalidad elegida; no cierra la sesión ni borra los consentimientos, reclamos o pagos en memoria.

`src/sesion.tsx` guarda la municipalidad elegida (también en la cuenta, si hay Supabase) y filtra todos los datos por ella.

Las pestañas son Inicio, Pagar, Reclamos, Obras y Asistente, en ese orden. Pagar conserva la ruta `/cuenta`. Inicio ya no tiene accesos: Recordatorios se abre con la campana de la barra superior y Mi perfil con el avatar.

Inicio resume la deuda pendiente con `repartoDeuda` (En mora y Por vencer) y `proximoVencimiento` (el vencimiento pendiente más cercano desde `HOY_EJEMPLO`). En Pagar, todas las deudas pendientes empiezan marcadas; `deudasSeleccionadas` y `totalSeleccionado` recalculan el total y el botón al marcar o desmarcar, y el botón se deshabilita si no hay nada marcado. Estas funciones viven en `packages/shared/src/pagos.ts`.

El pago es simulado: al confirmar, `registrarPagoSimulado` crea pagos en memoria con estado `pendiente` (solo el servidor confirma pagos), las deudas se ven como pagadas hasta cerrar la app y se abre la constancia con un QR dibujado, que no codifica nada. "Compartir" usa `Share` de React Native con un resumen sin datos personales (monto, fecha y número de operación) y "Descargar constancia" no genera ningún archivo. Los plazos, vencimientos y fechas de pago usan `HOY_EJEMPLO` (1 nov 2026) en vez de la fecha del teléfono.

El asistente se llama "Asistente" y no usa IA (la pantalla lo dice en su nota: "Prototipo: respuestas fijas de ejemplo"): `responderAsistente` (`packages/shared/src/asistente.ts`) responde con textos fijos si la pregunta menciona cuotas o la multa, y con un mensaje que orienta a las preguntas sugeridas o a hablar con una persona en cualquier otro caso. La conversación vive solo en la pantalla. La simulación de cuotas usa las deudas pendientes (o solo las vencidas) y la tasa ilustrativa del prototipo (1 % mensual, cuota fija); es informativa y "Pedir evaluación a Rentas" no envía nada. Atención humana es simulada: el tiempo de espera es de ejemplo y no hay nadie conectado; solo promete compartir la consulta con el asistente si el vecino lo autorizó en el consentimiento.

Reclamos: Nuevo reclamo (16) toma la foto con la cámara (`expo-image-picker`) y, si el vecino toca "Usar mi ubicación", lee el GPS (`expo-location`), siempre con permiso. Por ahora los dos se quedan en el teléfono: la foto no se sube a Storage, el punto del GPS no se guarda en el reclamo y la pantalla lo dice en una nota. Las pantallas 15, 17 y 18 siguen mostrando un dibujo fijo según la categoría en miniatura (`MiniaturaFoto` de `FotoSimulada.tsx`). El minimapa de la 16 es real, fijo y sin gestos: marca el punto del GPS si lo hay y, si no, la ubicación de ejemplo del predio (`UBICACIONES_PREDIO_EJEMPLO`); si el vecino cambia la dirección sin GPS, el mapa queda en el distrito sin marcador. El reclamo guarda el punto de ejemplo del predio, o ninguno si cambió la dirección. La ayuda de Reclamos lleva a Atención humana; no se muestra ningún teléfono. La ubicación parte de la dirección del predio y el vecino puede ajustarla a mano. `clasificarReclamo` (`packages/shared/src/reclamos.ts`) elige la categoría con palabras clave y `AREA_TIPO_RECLAMO` da el área; no hay IA. El plazo de ejemplo es de 10 días hábiles para todas las categorías. Al confirmar, `registrarReclamo` guarda el reclamo en memoria con el siguiente código de la municipalidad, estado `derivado` y fecha `HOY_EJEMPLO`, y abre su seguimiento. El estado lo cambia la municipalidad.

Obras: el mapa es real (ver «Mapa de obras» más abajo). La pantalla 19 filtra con los chips Todas, En ejecución y Concluidas; al tocar un marcador se resalta su tarjeta y la lista baja hasta ella. Con `/obras?obra=<id>` la obra llega seleccionada y centrada: así vuelven el ícono de mapa y "Ver en el mapa" del detalle (20), que solo aparecen si la obra tiene ubicación. El botón de recentrar vuelve al encuadre de las obras; no usa el GPS. El detalle muestra una imagen ilustrativa porque no hay fotos publicadas.

Mi perfil vive dentro de la pestaña Inicio. "Texto más grande" (`src/textoGrande.tsx`) agranda en memoria todos los textos de `Texto`. Cerrar sesión vuelve al ingreso, cierra la sesión de Supabase (`signOut`), si está configurado, y olvida en memoria el método de ingreso y el consentimiento. Privacidad y mis datos muestra y cambia los permisos que guardó el consentimiento; las solicitudes ARCO son simuladas. Sin smartphone usa un número SMS y un horario de ejemplo (`SMS_NUMERO_EJEMPLO`, `HORARIO_MODULO_EJEMPLO`) y la reserva de turno es simulada.

Recordatorios vive dentro de la pestaña Inicio; el detalle del aviso y "Cómo llegan los avisos" se abren encima de las pestañas. Los títulos y mensajes de los avisos salen de `packages/shared/src/avisos.ts` con los datos de la deuda y el `nombreCorto` de la obra (si la obra no lo tiene, el mensaje no la menciona). En "¿Por dónde te avisamos?" los canales van con interruptores y se pueden prender varios. Se guardan en memoria por municipalidad, empiezan con el canal preferido del vecino y siempre queda al menos uno (`alternarCanal` en `packages/shared/src/avisos.ts`). En la base sigue habiendo un solo `canal_preferido`; la lista de canales todavía no se guarda. Los mensajes de la pantalla 11 son ejemplos: no se envía nada.

## Panel web

| Página | Ruta | Archivo |
| --- | --- | --- |
| Ingreso (web-01) | `/ingreso` | `src/paginas/Ingreso.tsx` |
| Panel municipal (web-02) | `/panel` | `src/paginas/PanelMunicipal.tsx` |
| Recaudación y pagos (web-03) | `/recaudacion` | `src/paginas/Recaudacion.tsx` |
| Avisos y respuestas (web-04) | `/avisos` | `src/paginas/Avisos.tsx` |
| Reclamos por área (web-05) | `/reclamos` | `src/paginas/Reclamos.tsx` |
| Obras publicadas (web-06) | `/obras` | `src/paginas/Obras.tsx` |
| Atención humana (web-07) | `/atencion` | `src/paginas/AtencionHumana.tsx` |
| Alertas y auditoría (web-08) | `/alertas` | `src/paginas/Alertas.tsx` |
| Datos y accesos (web-09) | `/datos` | `src/paginas/DatosAccesos.tsx` |

Las 9 páginas siguen las maquetas `web-01` a `web-09` de `docs/design/turquesa/web`.

El ingreso es simulado: no hay autenticación real y cualquier usuario y contraseña entran. El selector de municipalidad solo ofrece las que tienen cifras de ejemplo para el panel (hoy, solo Lince), con el nombre que viene de los datos. El acceso por rol todavía no existe: el ingreso y Datos y accesos lo muestran como "Previsto". El pie de la barra lateral muestra el rol de ejemplo y sus iniciales (`PERSONAL_PANEL_EJEMPLO`).

Las cifras agregadas (recaudación, pagos a tiempo, gráficos, casos de atención humana, alertas) son de ejemplo, iguales a las del prototipo, y viven en `packages/shared/src/panel-ejemplo.ts`, separadas de los datos de vecinos. Los reclamos y las obras salen de `datos-ejemplo.ts`, filtrados por la municipalidad.

`src/estado.tsx` guarda la sesión y una copia en memoria de los reclamos, obras y casos de la municipalidad. Las cifras de la barra lateral y "Requiere tu decisión" se calculan con esa copia. Nada se guarda: al recargar, el panel vuelve al ingreso y a los datos de ejemplo.

Recaudación y Avisos solo muestran cifras agregadas, sin nombres ni rankings de vecinos. Las acciones cambian solo la copia en memoria y lo avisan en pantalla: "Usar variante B" marca la variante elegida sin cambiar ningún envío; "Responder y cerrar" deja el reclamo resuelto sin guardar nada ni avisar al vecino; "Corregir área" cambia el área; en Obras se puede publicar o despublicar, sumar 5 % de avance (la obra queda actualizada hoy) y agregar una obra nueva, que entra sin publicar y sin ubicación. La tarjeta "Vista del vecino" muestra en el mapa las obras publicadas con ubicación, con la misma copia en memoria: al cambiar «Publicada», el marcador aparece o desaparece al instante. En Atención humana, "Tomar" pasa el caso a "En atención"; en Alertas, el interruptor del simulador de cuotas solo cambia en el panel. La app del vecino no se entera de ninguno de estos cambios. Los casos, alertas, umbrales, auditorías, registro de accesos y solicitudes ARCO son de ejemplo, y esas páginas lo dicen al pie. La clasificación del reclamo se muestra sin porcentaje de confianza, porque sale de reglas fijas, y el detalle no muestra foto, porque el panel no recibe las fotos. El plazo va en rojo si venció, en ámbar si quedan 3 días o menos y en turquesa si quedan más. La zona de cada reclamo de ejemplo está en `zonaReclamo` del panel, porque la tabla `reclamos` no tiene zona. En Atención humana, la espera va en rojo desde `atencion.esperaLargaMinutos`; en la ruta del incidente, el paso con `alerta` va con borde rojo.

`src/estilos.css` solo usa variables CSS que `src/tema.ts` crea con los tokens de `@almira/shared` (`panelSizes` y `panelTypography` para las medidas y textos del panel). Los gráficos son HTML y CSS, sin librerías: cada barra lleva su cifra escrita y los de dos series (recaudación mensual y prueba A/B) llevan leyenda. Los componentes comunes (indicador, tarjeta, tabla, barras, nota, alerta, insignia) están en `src/componentes.tsx`. El mapa usa `leaflet` 1.9.4 y `react-leaflet` 5 (`src/MapaObras.tsx`).

## Modelo de datos

Cada tabla de datos lleva `municipalidad_id`.

- `vecinos` tiene una fila por persona y municipalidad: quien tributa en dos distritos tiene dos filas. `user_id` queda vacío hasta que vincula su DNI.
- Las llaves foráneas compuestas `(municipalidad_id, id)` impiden que una deuda, un pago o un reclamo apunte a un vecino de otra municipalidad, incluso con `service_role`.
- `reclamos.foto_ruta` es obligatoria y debe estar en la carpeta de su municipalidad.
- `obras.latitud` y `obras.longitud` son nulas (`20261109000001_obras_ubicacion.sql`): una obra sin coordenadas sale en la lista, pero no en el mapa.

## Seguridad

Las funciones de `supabase/migrations/20261031000002_rls.sql` viven en el esquema `privado`, que PostgREST no expone.

| Tabla | Vecino | Personal de la municipalidad | Solo `service_role` |
| --- | --- | --- | --- |
| `municipalidades` | Lee las activas | Lee las activas y la suya | Escribe |
| `personal` | Sin acceso | Lee su municipalidad | Escribe |
| `vecinos` | Lee su fila y cambia `canal_preferido` | Lee | Escribe el resto |
| `predios`, `deudas` | Lee las propias | Lee | Escribe |
| `pagos` | Lee los propios | Lee | Escribe |
| `recordatorios` | Lee los propios | Lee | Escribe |
| `reclamos` | Lee y crea los propios | Lee y cambia `estado`, `area` y `plazo` | Elimina |
| `obras` | Lee todas | Crea y actualiza las suyas | Elimina |

**Pendiente:** obras usa grant de tabla completa para authenticated; pasar a permisos por columna según CLAUDE.md. Por eso el personal de la municipalidad también puede escribir `latitud` y `longitud` de sus obras; los vecinos no, porque la política exige ser personal.

`anon` no tiene acceso a ninguna tabla. Un pago solo se confirma desde el servidor, nunca desde el cliente.

El bucket privado `evidencias` usa la ruta `{municipalidad_id}/{user_id}/{archivo}`. El vecino sube a su carpeta, el personal lee las de su municipalidad y nadie reemplaza ni borra evidencias desde el cliente.

Al agregar una tabla: incluye `municipalidad_id`, activa RLS y revoca los permisos de `anon` y `authenticated`, porque Supabase los concede por defecto en tablas nuevas.

## Datos de la app móvil

Con Supabase configurado y una sesión iniciada, la app lee de la base sus municipalidades, predios,
deudas, pagos, avisos, reclamos y obras (`apps/mobile/src/datos-remotos.ts`; los conversores de
fila a tipo están en `packages/shared/src/filas.ts`). Las políticas RLS dejan pasar solo las filas del
vecino: el vecino se enlaza con su cuenta al vincular un código (`vincular_contribuyente`). Sin
Supabase, la app sigue con los datos de ejemplo.

- **Pagos:** Almira no procesa pagos. `municipalidades.url_pago` guarda el portal oficial de cada
  municipalidad (es un dato, no va en el código) y la pantalla "Confirma tu pago" lleva a ese portal.
  Almira no confirma la operación.
- **Reclamos:** la foto se sube a `evidencias/{municipalidad}/{usuario}/{archivo}` y el reclamo se
  inserta con permisos por columna. Sin foto no se envía: `foto_ruta` es obligatoria.
- **Panel web:** sigue simulado (ingreso sin contraseña real, datos de ejemplo). Los permisos por rol
  del personal ya existen en la base, pero el panel todavía no los usa.

## Mapa de obras

El mapa es OpenStreetMap dibujado con Leaflet, sin API key (`docs/design/turquesa/MAPA.md`).

- `packages/shared/src/mapa.ts` tiene las teselas (`MAPA_TILES`), la atribución (`MAPA_ATRIBUCION`, con enlace a openstreetmap.org/copyright), `obrasConUbicacion` (solo obras publicadas con coordenadas), `encuadreMapa` (centro del distrito si no hay puntos; si hay, límites con margen) y `htmlMapaObras`, que arma un HTML completo con Leaflet 1.9.4 desde unpkg con SRI. Los colores entran como parámetro desde los tokens (`coloresMapa(colors)`) y los datos de las obras van escapados dentro del script.
- El HTML avisa con `postMessage`: `{ tipo: 'obra', id }` al tocar un marcador, `{ tipo: 'listo' }` al cargar la primera tesela y `{ tipo: 'error' }` si las teselas fallan (errores seguidos, sin conexión o 15 s sin cargar). Escucha `{ tipo: 'seleccionar', id }` en el iframe; en el WebView se llama `window.almiraMapa.seleccionar(id)` con `injectJavaScript`.
- App: `src/components/MapaObras.tsx` usa `react-native-webview` con `baseUrl` para que las teselas lleven Referer, como exige OpenStreetMap; los enlaces se abren en el navegador. `MapaObras.web.tsx` (Expo web) usa un iframe con `srcDoc` y solo acepta mensajes de ese iframe y de tipo conocido (`leerMensajeDelMapa`). Mientras carga se ve un fondo `subtle` con un indicador; si llega el error, el mapa se cambia por la nota "No se pudo cargar el mapa…" y la lista de obras sigue.
- El centro de cada distrito vive en `CENTROS_MAPA_EJEMPLO` (`centroMapaDe`); la base no tiene esa columna. Una municipalidad sin centro usa el de Lima.
- La atribución siempre se ve, sin el prefijo de Leaflet.

Límites: las teselas públicas de OpenStreetMap son para uso ligero; sirven para el prototipo, pero una app con mucho tráfico necesita un proveedor con clave. Las coordenadas de ejemplo se verificaron en OpenStreetMap (ver `MAPA.md`); en las obras por cuadras marcan el medio del tramo. El minimapa del reclamo usa el GPS solo para mostrar el punto; ese punto todavía no se guarda.

## Recordatorios y SMS

`supabase/functions/enviar-recordatorios` procesa los recordatorios con estado `programado`, canal `sms` y fecha vencida, y los envía con Twilio. Requiere `Authorization: Bearer <RECORDATORIOS_SECRETO>` y falla cerrada si el secreto no existe. Los secretos de Twilio (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` y `TWILIO_MESSAGING_SERVICE_SID` o `TWILIO_FROM`) se cargan con `supabase secrets set`, nunca en el repositorio.

- Canales `sms` y `whatsapp` salen por Twilio (`supabase/functions/_shared/twilio.ts`). WhatsApp usa el sandbox de Twilio (`TWILIO_WHATSAPP_FROM`): cada persona debe enviar antes el código "join …" al número del sandbox. En producción hace falta un número de empresa verificado por Meta y plantillas aprobadas.
- La app no tiene proveedor conectado: sus recordatorios se quedan en `programado`, no se marcan como enviados.
- Un recordatorio sin teléfono peruano válido pasa a `fallido`.
- Los logs no incluyen teléfonos ni mensajes.
- El monto del SMS usa `formatearSoles` de `supabase/functions/_shared/soles.ts`, una copia de `packages/shared/src/soles.ts` que debe coincidir con él (las Edge Functions no importan desde `packages/`).
- Falta el cron que invoque la función.

**Vincular WhatsApp:** en Recordatorios, el vecino con sesión real confirma su celular con un código SMS (`updateUser` + `verifyOtp` tipo `phone_change`, sin crear otra sesión). La función `vincular-whatsapp` guarda el celular en sus filas de `vecinos`, pone el canal preferido en WhatsApp y le escribe un mensaje de confirmación.

El ingreso con celular usa Phone Auth de Supabase (Authentication → Providers → Phone, con Twilio): `signInWithOtp` y `verifyOtp` en `src/auth.tsx`.

## Comandos

```bash
pnpm install
pnpm mobile
pnpm web
pnpm typecheck
pnpm test
pnpm build:web
```

Base de datos local, con Docker en marcha:

```bash
supabase start
supabase db reset
```
