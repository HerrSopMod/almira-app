// Contexto que se entrega al modelo: solo datos del contribuyente autenticado, con los totales
// ya calculados. NUNCA incluye el número de cuponera ni el DNI: ni siquiera se piden a la base.
import { aCentimos, esPendiente, formatearSoles, resumirDeudas } from './calculos.ts';
import type { DatosContribuyente, FilaDeuda } from './tipos.ts';

/** Oculta cualquier número de 8 dígitos (un DNI) que se cuele en un texto. */
export const ocultarDocumentos = (texto: string): string => texto.replace(/(?<!\d)\d{8}(?!\d)/g, '********');

const detalleDeuda = (d: FilaDeuda) => ({
  tributo: d.tipo,
  concepto: d.concepto,
  periodo: d.periodo,
  anio: d.anio,
  trimestre: d.trimestre,
  insoluto: formatearSoles(aCentimos(d.monto_insoluto)),
  gastos_emision: formatearSoles(aCentimos(d.gastos_emision)),
  interes: formatearSoles(aCentimos(d.interes_actualizacion) + aCentimos(d.interes_moratorio)),
  descuento: formatearSoles(aCentimos(d.descuento)),
  pagos: formatearSoles(aCentimos(d.pagos_aplicados)),
  saldo: formatearSoles(aCentimos(d.saldo)),
  vencimiento: d.vencimiento,
  nro_valor: d.nro_valor,
  expediente_coactivo: d.exp_coactivo,
});

export function construirContexto(datos: DatosContribuyente, hoy: string) {
  const pagadasPorAnio = new Map<string, number>();
  for (const d of datos.deudas) {
    if (d.estado === 'pagada') {
      const anio = String(d.anio ?? '');
      pagadasPorAnio.set(anio, (pagadasPorAnio.get(anio) ?? 0) + 1);
    }
  }
  return {
    fecha_de_hoy: hoy,
    contribuyente: { nombre: datos.nombre, codigo_contribuyente: datos.codigoContribuyente },
    municipalidad: { nombre: datos.municipalidad.nombre, telefono_de_ayuda: datos.municipalidad.telefonoAyuda },
    predios: datos.predios,
    // Totales ya calculados: el modelo no hace cuentas.
    resumen: resumirDeudas(datos.deudas, hoy),
    periodos_pendientes: datos.deudas.filter(esPendiente).map(detalleDeuda),
    periodos_pagados_por_anio: Object.fromEntries(pagadasPorAnio),
    ultimos_pagos: datos.pagos.slice(0, 5).map((p) => ({
      monto: formatearSoles(aCentimos(p.monto)),
      medio: p.medio,
      operacion: p.referencia,
      fecha: p.creado_en?.slice(0, 10) ?? null,
    })),
  };
}

export const contextoComoTexto = (datos: DatosContribuyente, hoy: string): string =>
  ocultarDocumentos(JSON.stringify(construirContexto(datos, hoy)));
