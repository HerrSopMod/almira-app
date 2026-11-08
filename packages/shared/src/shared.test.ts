import { describe, expect, it } from 'vitest';
import { deudas, municipalidades, vecinos } from './datos-ejemplo';
import { formatearFecha, formatearSoles, sumarDeudas, deudasPendientes } from './formato';
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

  it('mantiene las medidas actuales hasta medirlas en el prototipo', () => {
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
