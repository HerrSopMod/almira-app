# Plantillas de WhatsApp para Meta

Cuatro plantillas para los recordatorios, más una quinta, neutra, para quien tiene deuda en cobranza coactiva. Todas se envían a aprobación como categoría **Utility** (utilidad), idioma **Español (PE)** (`es_PE`) o, si tu cuenta no lo ofrece, **Español** (`es`). La función prueba primero `es_PE` y, si Meta responde que esa plantilla no existe en ese idioma, reintenta con `es`. Para fijar otro idioma, usa el secreto `WA_IDIOMA`.

Los nombres deben quedar **exactamente** así, porque son los que usa `enviar-recordatorios`:

| Plantilla | Nombre en Meta | Cuándo sale |
|---|---|---|
| Vencimiento | `almira_vencimiento` | 3 días antes del vencimiento de una deuda pendiente |
| Pendiente | `almira_pendiente` | Como máximo cada 15 días mientras haya deuda vencida |
| Pendiente (informativa) | `almira_pendiente_info` | En vez de la anterior, si hay deuda en cobranza coactiva |
| Pago confirmado | `almira_pago_confirmado` | Tras un pago confirmado |
| Bienvenida | `almira_bienvenida` | Al activar los recordatorios en la app |

Ninguna lleva DNI ni número de cuponera. Las variables son solo nombre, municipalidad, tributo, monto, fechas y número de operación. Todas incluyen la línea de baja («responde BAJA»), salvo la de pago confirmado, que no es un aviso de cobro.

Al crear cada plantilla en el Administrador de WhatsApp, Meta pide un **ejemplo** de cada variable: usa los de las tablas de abajo.

---

## 1. `almira_vencimiento`

```
Hola {{1}} 👋 Te escribe Almira, de la Municipalidad de {{2}}. Te recordamos que tu {{3}} vence el {{4}}. Pagando a tiempo evitas intereses y recargos. Puedes hacerlo desde la app en pocos pasos. ¡Gracias por cumplir con tu comunidad! 💚 Si prefieres no recibir estos avisos, responde BAJA.
```

| Variable | Qué lleva | Ejemplo |
|---|---|---|
| `{{1}}` | Primer nombre | `Rosa` |
| `{{2}}` | Municipalidad, sin «Municipalidad de» | `Lince` |
| `{{3}}` | Tributo | `impuesto predial` (o `arbitrios municipales`, o ambos con «y») |
| `{{4}}` | Fecha de vencimiento | `15 de noviembre` |

## 2. `almira_pendiente`

```
Hola {{1}} 😊 Soy Almira. Vimos que tienes S/ {{2}} pendientes con la Municipalidad de {{3}}. Puedes revisarlos y pagarlos cuando gustes desde la app. Si ya pagaste, ¡gracias y disculpa la molestia! Para dejar de recibir estos avisos, responde BAJA.
```

| Variable | Qué lleva | Ejemplo |
|---|---|---|
| `{{1}}` | Primer nombre | `Rosa` |
| `{{2}}` | Total pendiente, sin «S/» | `120.50` |
| `{{3}}` | Municipalidad | `Lince` |

## 3. `almira_pago_confirmado`

```
¡Gracias, {{1}}! 🎉 Recibimos tu pago de S/ {{2}}. Tu número de operación es {{3}}. Puedes descargar tu constancia desde la app.
```

| Variable | Qué lleva | Ejemplo |
|---|---|---|
| `{{1}}` | Primer nombre | `Rosa` |
| `{{2}}` | Monto pagado, sin «S/» | `41.35` |
| `{{3}}` | Número de operación | `OP-90500` |

## 4. `almira_bienvenida`

```
¡Hola {{1}}! 👋 Activaste los recordatorios de Almira. Te avisaremos antes de cada vencimiento. Puedes desactivarlos cuando quieras respondiendo BAJA.
```

| Variable | Qué lleva | Ejemplo |
|---|---|---|
| `{{1}}` | Primer nombre | `Rosa` |

## 5. `almira_pendiente_info` (cobranza coactiva)

Informativa y neutra: sin monto, sin plazos y sin lenguaje de presión. Es la única que no estaba en la lista original: hace falta para cumplir la regla de no presionar a quien tiene una deuda en cobranza coactiva.

```
Hola {{1}}, te escribe Almira. Hay información disponible sobre tu cuenta en la Municipalidad de {{2}}. Puedes consultarla cuando gustes desde la app. Para dejar de recibir estos avisos, responde BAJA.
```

| Variable | Qué lleva | Ejemplo |
|---|---|---|
| `{{1}}` | Primer nombre | `Rosa` |
| `{{2}}` | Municipalidad | `Pueblo Libre` |

---

## Notas para la aprobación

- **Categoría Utility.** Meta puede reclasificar una plantilla a *Marketing* si la lee como promocional. Las frases como «¡Gracias por cumplir con tu comunidad! 💚» son las que más arriesgan: si la rechazan o la reclasifican, quita esa frase y vuelve a enviarla.
- **Variables:** Meta no admite una variable al comienzo ni al final del texto, ni dos variables pegadas. Las plantillas cumplen eso. La función quita saltos de línea, tabulaciones y espacios repetidos de cada valor.
- **Ejemplos obligatorios:** sin ejemplos por variable, el envío a aprobación se rechaza.
- **Baja:** la respuesta «BAJA», «STOP» o «NO» la procesa `whatsapp-webhook`. Si cambias el texto de la línea de baja, conserva esas palabras.
- Aprobación: suele tardar de minutos a un día. Una plantilla rechazada no se puede editar: se crea otra con otro nombre y se cambia el nombre en `PLANTILLAS` de `supabase/functions/enviar-recordatorios/logica.ts`.

## Texto de consentimiento en la app

Versión `wa-2026-11-12-v1`:

> Acepto recibir recordatorios de pago de mi Municipalidad por WhatsApp. Puedo desactivarlos cuando quiera.

Si cambias este texto, sube la versión en `apps/almira_flutter/lib/shared/models/preferencia_whatsapp.dart` (`versionConsentimientoWhatsapp`): la versión queda guardada en `preferencias_notificacion.consentimiento_version` junto con la fecha de aceptación.
