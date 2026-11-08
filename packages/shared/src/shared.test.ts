import { describe, expect, it } from 'vitest';
import {
  deudas,
  HOY_EJEMPLO,
  municipalidades,
  obras,
  pagos,
  predios,
  reclamos,
  recordatorios,
  USUARIO_EJEMPLO,
  vecinos,
} from './datos-ejemplo';
import {
  DETALLE_MEDIO_PAGO,
  ETIQUETA_MEDIO_PAGO,
  etiquetaPlazo,
  fechaLimitePlazo,
  formatearFecha,
  formatearFechaCorta,
  formatearHora,
  formatearSoles,
  nombreDistrito,
  sumarDeudas,
  deudasPendientes,
  textoVencimiento,
} from './formato';
import { colors, sizes, spacing } from './tokens';

describe('tokens', () => {
  it('aplica los colores de la guía de estilos del prototipo', () => {
    expect(colors.header).toBe('#800404');
    expect(colors.primary).toBe('#C00000');
    expect(colors.chartSecondary).toBe('#F4A6A6');
    expect(colors.backgroundPink).toBe('#F7ECEC');
    expect(colors.pendingDebt).toBe('#FFFFCC');
    expect(colors.neutral).toBe('#E8E8E8');
    expect(colors.background).toBe('#FFFFFF');
    expect(colors.surface).toBe('#FFFFFF');
    expect(colors.text).toBe('#2B2B2B');
    expect(colors.textSecondary).toBe('#595959');
    expect(colors.lines).toBe('#808080');
    expect(colors.paid).toBe('#2E8B57');
    expect(colors.paidSoft).toBe('#E2F3E8');
    expect(colors.notice3).toBe('#5B1428');
    expect(colors.notice2).toBe('#9A5563');
    expect(colors.notice1).toBe('#E9C1C6');
  });

  it('usa el gris de apoyo para los bordes claros del prototipo', () => {
    expect(colors.border).toBe('#E8E8E8');
  });

  it('usa las medidas de las imágenes del prototipo', () => {
    expect(sizes.button).toBe(48);
    expect(sizes.input).toBe(46);
    expect(spacing.margin).toBe(18);
  });
});

describe('formato', () => {
  it('antepone S/ con espacio duro y usa miles con coma', () => {
    expect(formatearSoles(142.5)).toBe('S/ 142.50');
    expect(formatearSoles(1250000)).toBe('S/ 1,250,000.00');
  });

  it('escribe la fecha en español', () => {
    expect(formatearFecha('2025-02-28')).toBe('28 de febrero de 2025');
  });

  it('escribe la fecha corta con el mes en minúsculas, como el prototipo', () => {
    expect(formatearFechaCorta('2026-10-28')).toBe('28 oct 2026');
    expect(formatearFechaCorta('2026-11-01T09:41:00-05:00')).toBe('1 nov 2026');
  });

  it('escribe la hora con minutos de dos cifras', () => {
    expect(formatearHora('2026-11-01T09:41:00')).toBe('9:41 h');
    expect(formatearHora('2026-11-01T14:05:00')).toBe('14:05 h');
  });

  it('dice "Venció" solo si la fecha ya pasó', () => {
    expect(textoVencimiento('2026-11-30', HOY_EJEMPLO)).toBe('Vence 30 nov 2026');
    expect(textoVencimiento('2026-11-01', HOY_EJEMPLO)).toBe('Vence 1 nov 2026');
    expect(textoVencimiento('2026-10-15', HOY_EJEMPLO)).toBe('Venció 15 oct 2026');
  });

  it('cuenta los plazos en días hábiles y nunca muestra días negativos', () => {
    // R-01842 del prototipo: creado el jueves 22 oct con 10 días hábiles.
    const limite = fechaLimitePlazo('2026-10-22', 10);
    expect(limite).toBe('2026-11-04');
    expect(etiquetaPlazo(limite, HOY_EJEMPLO)).toBe('Quedan 3 d');
    expect(etiquetaPlazo(limite, '2026-11-04')).toBe('Vence hoy');
    expect(etiquetaPlazo(limite, '2026-11-05')).toBe('Vencido');
    expect(etiquetaPlazo(limite, '2026-12-20')).toBe('Vencido');
    // Si se crea en fin de semana, el plazo empieza el lunes.
    expect(fechaLimitePlazo('2026-10-31', 1)).toBe('2026-11-02');
  });

  it('nombra los medios de pago del prototipo', () => {
    expect(Object.values(ETIQUETA_MEDIO_PAGO)).toEqual([
      'Yape',
      'Plin',
      'Tarjeta de débito o crédito',
      'Banca móvil o agente',
    ]);
    expect(DETALLE_MEDIO_PAGO.banca_movil).toBe('Con código de pago');
  });

  it('obtiene el distrito del nombre de la municipalidad', () => {
    expect(nombreDistrito({ nombre: 'Municipalidad de Villa Verde' })).toBe('Villa Verde');
    expect(nombreDistrito({ nombre: 'Municipalidad Distrital de Lince' })).toBe('Lince');
    expect(nombreDistrito({ nombre: 'Lince' })).toBe('Lince');
  });
});

describe('datos de ejemplo', () => {
  const lince = municipalidades[0]!;
  const rosa = vecinos.find(
    (vecino) => vecino.municipalidadId === lince.id && vecino.userId === USUARIO_EJEMPLO.id,
  )!;
  const deudasDeRosa = deudas.filter((deuda) => deuda.vecinoId === rosa.id);

  it('usa Lince como municipalidad principal y a Rosa como vecina', () => {
    expect(lince.nombre).toBe('Municipalidad de Lince');
    expect(USUARIO_EJEMPLO.nombre).toBe('Rosa');
    expect(rosa.nombre).toBe('Rosa Quispe Huamán');
  });

  it('mantiene el total de S/ 120.50 de las pantallas', () => {
    expect(sumarDeudas(deudasPendientes(deudasDeRosa))).toBeCloseTo(120.5, 2);
    expect(formatearSoles(sumarDeudas(deudasPendientes(deudasDeRosa)))).toBe('S/ 120.50');
  });

  it('separa la multa en mora de los arbitrios por vencer', () => {
    const multa = deudasDeRosa.find((deuda) => deuda.tipo === 'multa')!;
    const arbitrios = deudasDeRosa.find(
      (deuda) => deuda.tipo === 'arbitrios' && deuda.estado !== 'pagada',
    )!;
    expect(formatearSoles(multa.montoInsoluto)).toBe('S/ 40.00');
    expect(multa.estado).toBe('vencida');
    expect(formatearSoles(arbitrios.montoInsoluto)).toBe('S/ 80.50');
    expect(arbitrios.estado).toBe('vigente');
    expect(arbitrios.vencimiento).toBe('2026-11-30');
  });

  it('cada pago confirmado apunta a una deuda pagada por el mismo monto', () => {
    for (const pago of pagos) {
      const deuda = deudas.find((fila) => fila.id === pago.deudaId)!;
      expect(deuda.estado).toBe('pagada');
      expect(pago.monto).toBe(deuda.montoInsoluto + deuda.interesMoratorio);
    }
  });

  it('cada vecino pertenece a una municipalidad existente', () => {
    const ids = new Set(municipalidades.map((municipalidad) => municipalidad.id));
    expect(vecinos.every((vecino) => ids.has(vecino.municipalidadId))).toBe(true);
  });

  it('ninguna fila enlaza datos de municipalidades distintas', () => {
    const municipalidadDe = (filas: { id: string; municipalidadId: string }[]) =>
      new Map(filas.map((fila) => [fila.id, fila.municipalidadId]));
    const deVecino = municipalidadDe(vecinos);
    const dePredio = municipalidadDe(predios);
    const deDeuda = municipalidadDe(deudas);
    const ids = new Set(municipalidades.map((municipalidad) => municipalidad.id));

    for (const fila of [...predios, ...deudas, ...pagos, ...recordatorios, ...reclamos]) {
      expect(deVecino.get(fila.vecinoId)).toBe(fila.municipalidadId);
    }
    for (const deuda of deudas) {
      if (deuda.predioId) expect(dePredio.get(deuda.predioId)).toBe(deuda.municipalidadId);
    }
    for (const fila of [...pagos, ...recordatorios]) {
      expect(deDeuda.get(fila.deudaId)).toBe(fila.municipalidadId);
    }
    for (const obra of obras) {
      expect(ids.has(obra.municipalidadId)).toBe(true);
    }
  });

  it('guarda las fotos de reclamos en la carpeta de su municipalidad', () => {
    expect(
      reclamos.every((reclamo) => reclamo.fotoRuta.split('/')[0] === reclamo.municipalidadId),
    ).toBe(true);
  });
});
