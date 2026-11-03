# Almira

App para que vecinos de distintas municipalidades de Lima paguen tributos y reclamen con evidencia.

Este repositorio es un esqueleto con datos de ejemplo. Lee `docs/ARCHITECTURE.md` para ver cómo está organizado.

## Relación con el Modelo del Sistema Viable (MSV)

Almira se diseña como caso de estudio del curso SI801 Modelo del Sistema Viable (UNI, FIIS, 26-II). Este repositorio es el prototipo que acompaña el análisis del Sistema 3 (control y gestión interna) del MSV de Almira.

| Elemento del MSV | Cómo aparece en Almira |
| --- | --- |
| Unidad operativa (S1) | Cada municipalidad es una unidad autónoma que contrata el servicio. Por eso la municipalidad es un dato seleccionable y todas las tablas llevan `municipalidad_id` con RLS. |
| Sistema 3 (dirección operativa) | Almira negocia metas y recursos con cada municipalidad mediante un acuerdo de gestión y recibe su rendición de cuentas. No tiene autoridad jerárquica sobre ellas: su autoridad nace del convenio. |
| Sistema 2 (coordinación) | Reglas comunes de reparto de la capacidad de mensajería y recordatorios entre municipalidades. |
| Sistema 3* (auditoría) | Verificación por muestreo del asistente, los reclamos y la conciliación de pagos, separada de quien gestiona las cuentas. |
| Panel municipal | `apps/web` es el punto donde la municipalidad ve su situación y rinde cuentas al S3. |
| Aplicación de vecinos | `apps/mobile` es la operación de cada unidad frente al vecino. |

Límites de diseño que se reflejan en el código: Almira no gestiona las áreas de la municipalidad, no decide tributos ni cobra coactivamente, y los pagos solo se confirman desde el servidor.

Estado: el diseño del S3 está documentado, pero el prototipo todavía no opera con usuarios reales. Lo que se muestra son datos de ejemplo y el piloto con una municipalidad sigue por validar. Este repositorio no afirma resultados medidos ni certificaciones.
