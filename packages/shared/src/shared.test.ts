import { describe, expect, it } from 'vitest';
import { deudas, municipalidades, vecinos } from './datos-ejemplo';
import { formatearFecha, formatearSoles, sumarDeudas, deudasPendientes } from './formato';
import { colors, sizes, spacing } from './tokens';

describe('tokens', () => {
  it('aplica los valores del texto de DESIGN.md', () => {
    expect(colors.background).toBe('#FFFFFF');
    expect(colors.primary).toBe('#0B7F86');
    expect(sizes.button).toBe(52);
    expect(spacing.margin).toBe(20);
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
});

describe('datos de ejemplo', () => {
  it('mantiene el total de S/ 480.50 de las pantallas', () => {
    const propias = deudas.filter((deuda) => deuda.vecinoId === 'v-carlos-sa');
    expect(sumarDeudas(deudasPendientes(propias))).toBe(480.5);
  });

  it('cada vecino pertenece a una municipalidad existente', () => {
    const ids = new Set(municipalidades.map((municipalidad) => municipalidad.id));
    expect(vecinos.every((vecino) => ids.has(vecino.municipalidadId))).toBe(true);
  });
});
