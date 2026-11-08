import { describe, expect, it } from 'vitest';
import {
  deudas,
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
  formatearFecha,
  formatearSoles,
  nombreDistrito,
  sumarDeudas,
  deudasPendientes,
} from './formato';
import { colors, sizes, spacing } from './tokens';

describe('tokens', () => {
  it('aplica los colores de la guía de estilos del prototipo', () => {
    expect(colors.header).toBe('#0A6D72');
    expect(colors.primary).toBe('#0B7F86');
    expect(colors.chartSecondary).toBe('#79D5DC');
    expect(colors.backgroundPink).toBe('#E3F6F5');
    expect(colors.pendingDebt).toBe('#FFFFCC');
    expect(colors.neutral).toBe('#D6E3E4');
    expect(colors.background).toBe('#FFFFFF');
    expect(colors.surface).toBe('#FFFFFF');
    expect(colors.text).toBe('#0F2A2E');
    expect(colors.textSecondary).toBe('#5B6B70');
    expect(colors.lines).toBe('#6E797A');
    expect(colors.paid).toBe('#2E9E6B');
    expect(colors.paidSoft).toBe('#EAF6F0');
    expect(colors.notice3).toBe('#004F54');
    expect(colors.notice2).toBe('#2A7A80');
    expect(colors.notice1).toBe('#C3DFE4');
  });

  it('usa el gris de apoyo para los bordes claros del prototipo', () => {
    expect(colors.border).toBe('#D6E3E4');
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
