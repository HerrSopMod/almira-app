# Función `asistente`

Responde las preguntas del vecino sobre sus tributos con Gemini. Se llama desde la app (`supabase.functions.invoke('asistente')`) con la sesión de la persona.

## Cómo funciona

1. Entra `{ mensaje, historial }`: el mensaje, hasta 500 caracteres, y los últimos 10 del historial (`{ rol: 'usuario' | 'asistente', texto }`).
2. Con el **JWT de la persona** (nunca la service key) lee su contribuyente, sus predios, sus deudas y sus últimos pagos. Las políticas RLS limitan todo a su propio contribuyente.
3. Calcula **en código** el saldo total, el saldo por tributo, los próximos vencimientos y si hay deuda coactiva (`calculos.ts`). El modelo recibe esos totales ya hechos y no suma ni resta.
4. El contexto **no lleva el número de cuponera ni el DNI**: ni se piden a la base, y cualquier número de 8 dígitos que se cuele se oculta (`contexto.ts`).
5. Llama a Gemini (`gemini.ts`) con temperatura 0.25 y un máximo de 600 tokens de salida, y devuelve `{ respuesta, acciones }`. Las acciones válidas son `ver_estado_cuenta`, `pagar`, `ver_historial` y `descargar_cuponera`; cualquier otra se descarta.
6. Límite de uso: 30 mensajes por hora y por persona (función SQL `consumir_cupo_asistente`).

Si algo falla (cuota, tiempo agotado, servicio caído, falta la clave), la persona recibe un mensaje amable y genérico, y el detalle queda solo en los logs del servidor (`supabase functions logs`… en el panel de Supabase → Edge Functions → asistente → Logs).

## Variables

| Variable | Para qué | Por defecto |
| --- | --- | --- |
| `GEMINI_API_KEY` | Clave de la API de Gemini (obligatoria) | — |
| `GEMINI_MODEL` | Modelo de la familia Flash o Flash-Lite | `gemini-3.5-flash-lite` |
| `ASISTENTE_LIMITE_HORA` | Mensajes por hora y por persona | `30` |

## Puesta en marcha

1. **Clave:** en [Google AI Studio](https://aistudio.google.com/apikey) crea una clave de API. No la pegues en el chat ni en el código.
2. **Migración:** aplica `supabase/migrations/20261112000001_asistente_cupo.sql` (crea la tabla `asistente_uso` y la función del límite).
3. **Secreto y despliegue**, desde la raíz del repo:

```bash
supabase secrets set GEMINI_API_KEY=tu_clave
supabase functions deploy asistente
```

Para cambiar de modelo: `supabase secrets set GEMINI_MODEL=gemini-3.8-flash` (no hace falta volver a desplegar).

`verify_jwt` queda activado (es el valor por defecto): solo entra quien tiene una sesión de la app.

## Pruebas

Las pruebas están en `packages/shared/src/asistente-funcion.test.ts` y corren con `pnpm test`. Usan un Gemini simulado y un cliente de Supabase falso que reparte los datos por JWT. Comprueban que:

- solo se leen datos de la persona autenticada y nunca se piden `dni` ni `numero_cuponera`;
- el contexto no contiene cuponera ni DNI, y los totales llegan calculados;
- una persona no obtiene datos de otra, diga lo que diga en el mensaje o en el historial;
- los errores de Gemini no se filtran al usuario y el límite de uso se respeta.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `index.ts` | Conecta el manejador con Supabase, `fetch` y `Deno` |
| `manejador.ts` | Flujo completo, con sus dependencias inyectadas |
| `calculos.ts` | Totales, vencimientos y formato de soles |
| `contexto.ts` | Contexto para el modelo, sin datos privados |
| `prompt.ts` | Instrucción de sistema |
| `gemini.ts` | Cliente de la API de Gemini |
| `tipos.ts` | Tipos y acciones válidas |
