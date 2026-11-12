# Recordatorios por WhatsApp: puesta en marcha

Pasos manuales, en orden. Lo de código ya está hecho: migración, funciones `enviar-recordatorios` y `whatsapp-webhook`, y la pantalla en Mi perfil. Las plantillas están en [whatsapp-plantillas.md](whatsapp-plantillas.md).

Valores que vas a ir juntando (guárdalos en un lugar privado, nunca en el repositorio ni en el chat):

| Valor | De dónde sale | Secreto |
|---|---|---|
| ID del número de teléfono | WhatsApp > Configuración de la API | `WA_PHONE_NUMBER_ID` |
| Token permanente | Usuario del sistema (paso 4) | `WA_ACCESS_TOKEN` |
| Secreto de la app | Configuración de la app > Básica | `WA_APP_SECRET` |
| Token de verificación | Lo inventas tú (una cadena larga al azar) | `WA_VERIFY_TOKEN` |
| Secreto de la ejecución programada | Lo inventas tú (otra cadena larga al azar) | `RECORDATORIOS_SECRETO` |

## 1. Crear la app en Meta

1. Entra a <https://developers.facebook.com/apps> con la cuenta que administrará Almira y pulsa **Crear app**.
2. Elige el caso de uso **Otro** y el tipo de app **Empresa** (Business). Ponle nombre (por ejemplo, «Almira») y vincula (o crea) tu **portfolio comercial**.
3. En el panel de la app, busca el producto **WhatsApp** y pulsa **Configurar**.

## 2. Agregar los números permitidos (modo de prueba, hasta 5)

Mientras la cuenta esté en modo de prueba, Meta te da un **número de prueba** y solo deja escribir a números que tú autorices.

1. En **WhatsApp > Configuración de la API**, copia el **Identificador de número de teléfono** (`WA_PHONE_NUMBER_ID`).
2. En la sección **Para**, abre **Administrar lista de números de teléfono** y agrega hasta 5 celulares (los de tu equipo). A cada uno le llega un código por WhatsApp que se confirma ahí mismo.
3. Para confirmar que todo funciona antes de seguir, envía la plantilla de ejemplo `hello_world` desde esa misma pantalla («Enviar mensaje»).

Pasar a producción (cualquier número) exige verificar la empresa y poner un número propio: no hace falta para la demostración.

## 3. Secreto de la app

**Configuración de la app > Básica > Clave secreta de la app > Mostrar**. Es `WA_APP_SECRET`: con él, `whatsapp-webhook` comprueba que cada aviso viene de Meta.

## 4. Token permanente (usuario del sistema)

El token temporal de la pantalla de la API vence a las 24 horas. Para uno permanente:

1. Entra a <https://business.facebook.com/settings> y elige tu portfolio.
2. **Usuarios > Usuarios del sistema > Agregar**. Nombre: `almira`, rol **Administrador**.
3. **Asignar activos**: agrega tu **app** (control total) y tu **cuenta de WhatsApp Business** (control total).
4. **Generar token**: elige la app, caducidad **Nunca** y marca los permisos `whatsapp_business_messaging` y `whatsapp_business_management`.
5. Copia el token: es `WA_ACCESS_TOKEN`. Meta no lo vuelve a mostrar.

## 5. Plantillas

1. Abre <https://business.facebook.com/wa/manage/message-templates>.
2. **Crear plantilla** para cada una de las cinco de [whatsapp-plantillas.md](whatsapp-plantillas.md): categoría **Utility**, idioma **Español (PE)** o **Español**, el nombre exacto, el texto y los ejemplos de las variables.
3. Espera la aprobación (de minutos a un día). Hasta entonces los envíos fallarán con el código 132001 o 132000.

## 6. Base de datos

Se te muestra el SQL antes de aplicarlo. Cuando lo apruebes:

```bash
supabase db query --linked -f supabase/migrations/20261112000002_recordatorios_whatsapp.sql
supabase db query --linked -f supabase/tests/recordatorios_whatsapp.sql
```

La segunda corre una prueba que no deja nada guardado: debe terminar con un error que empieza con `RESULTADO` y no contiene `FALLA`.

## 7. Secretos y funciones

```bash
supabase secrets set WA_PHONE_NUMBER_ID=... WA_ACCESS_TOKEN=... WA_APP_SECRET=... WA_VERIFY_TOKEN=... RECORDATORIOS_SECRETO=...
supabase functions deploy enviar-recordatorios
supabase functions deploy whatsapp-webhook
```

`supabase/config.toml` ya fija `verify_jwt = false` en las dos funciones: Meta y pg_cron no mandan un JWT de usuario. Cada función se autoriza sola (firma del webhook y `RECORDATORIOS_SECRETO`).

Si usas `WA_IDIOMA` (por defecto `es_PE`), agrégalo en el mismo comando.

## 8. Webhook

1. En **WhatsApp > Configuración**, sección **Webhook**, pulsa **Editar**.
2. **URL de devolución de llamada**: `https://<REF_DEL_PROYECTO>.supabase.co/functions/v1/whatsapp-webhook`
3. **Token de verificación**: el mismo valor que pusiste en `WA_VERIFY_TOKEN`.
4. **Verificar y guardar**. Si falla, revisa que la función esté desplegada y el token coincida.
5. En **Campos del webhook**, suscríbete a **`messages`**.

## 9. Programar el envío diario (pg_cron)

1. En el panel de Supabase, **Database > Extensions**, activa **pg_cron** y **pg_net**.
2. Abre [`supabase/cron-recordatorios.sql`](../supabase/cron-recordatorios.sql), cambia `<REF_DEL_PROYECTO>` y `<RECORDATORIOS_SECRETO>` y córrelo una vez en el editor SQL.

Queda programado a las **10:00 de Lima (15:00 UTC)**. Para verlo: `select * from cron.job;`.

## 10. Probar de punta a punta

1. Instala la app, entra con una cuenta con cuponera vinculada y ve a **Mi perfil > Recordatorios por WhatsApp**.
2. Activa con uno de los números permitidos. Debe llegar la bienvenida.
3. Responde **BAJA**: llega la confirmación y el interruptor de la app se apaga al reabrir Mi perfil.
4. Ejecución manual (solo entre 9:00 y 20:00 de Lima; fuera de ese horario no envía nada):

```bash
curl -X POST "https://<REF_DEL_PROYECTO>.supabase.co/functions/v1/enviar-recordatorios" \
  -H "Authorization: Bearer <RECORDATORIOS_SECRETO>" \
  -H "Content-Type: application/json" \
  -d '{"accion":"ejecutar"}'
```

Responde un resumen (`candidatos`, `enviados`, `fallidos`, `omitidos`, `duplicados`). El detalle de cada mensaje queda en la tabla `recordatorios_enviados`.

## Cosas a tener presente

- **El número no se verifica con un código.** Quien activa los recordatorios escribe su celular y la función le manda la bienvenida; nadie confirma que sea suyo. Por eso la bienvenida está limitada a 3 por contribuyente al día, lleva la línea de baja, y en modo de prueba solo llega a los números que autorizaste. Para producción conviene reutilizar el celular que la persona ya confirmó con el código de 6 dígitos.
- **El pago confirmado y el horario.** El aviso de pago sale en la siguiente ejecución (10:00). Si lo quieres al instante, se puede llamar a la función justo después de pagar; hoy no se hace.
- **Cupo por ejecución.** Cada corrida procesa hasta 300 avisos, con una pausa de 150 ms entre envíos.
- **Datos que nunca salen.** Ni el DNI ni el número de cuponera se guardan en estas tablas ni viajan en los mensajes. Los teléfonos se enmascaran en los logs.
- **Reemplazo de la función anterior.** `enviar-recordatorios` antes enviaba SMS y WhatsApp por Twilio desde la tabla `recordatorios`. Esta versión la reemplaza. Twilio sigue en `_shared/twilio.ts` para `vincular-whatsapp`.
