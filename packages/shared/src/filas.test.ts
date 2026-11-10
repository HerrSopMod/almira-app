import { describe, expect, it } from 'vitest';
import { deudaDeFila, municipalidadDeFila, obraDeFila, reclamoDeFila } from './filas';

describe('filas de Supabase a tipos de la app', () => {
  it('convierte una municipalidad con su enlace de pago', () => {
    const m = municipalidadDeFila({
      id: 'a',
      slug: 'lince',
      nombre: 'Municipalidad de Lince',
      zona: 'Lima Centro',
      telefono_ayuda: null,
      aviso_destacado: null,
      url_pago: 'https://ejemplo.pe/pagos',
      activa: true,
    });
    expect(m.urlPago).toBe('https://ejemplo.pe/pagos');
    expect(m.telefonoAyuda).toBeNull();
    expect(m.activa).toBe(true);
  });

  it('lee los montos numeric aunque lleguen como texto', () => {
    const d = deudaDeFila({
      id: 'd',
      municipalidad_id: 'm',
      vecino_id: 'v',
      predio_id: null,
      tipo: 'arbitrios',
      concepto: 'Arbitrios',
      periodo: '4.º trimestre',
      monto_insoluto: '80.50',
      interes_moratorio: 0,
      vencimiento: '2026-11-30',
      estado: 'vigente',
    });
    expect(d.montoInsoluto).toBe(80.5);
    expect(d.interesMoratorio).toBe(0);
    expect(d.predioId).toBeNull();
  });

  it('deja en null el punto y el plazo que faltan en un reclamo', () => {
    const r = reclamoDeFila({
      id: 'r',
      municipalidad_id: 'm',
      vecino_id: 'v',
      codigo: 'R-1',
      tipo: 'alumbrado',
      titulo: 'Poste sin luz',
      estado: 'derivado',
      foto_ruta: 'm/u/1.jpg',
      latitud: null,
      longitud: null,
      plazo: null,
      plazo_dias: 10,
      creado_en: '2026-11-09',
    });
    expect(r.latitud).toBeNull();
    expect(r.plazoDias).toBe(10);
    expect(r.descripcion).toBeNull();
  });

  it('convierte los hitos y las coordenadas de una obra', () => {
    const o = obraDeFila({
      id: 'o',
      municipalidad_id: 'm',
      nombre: 'Parque',
      ubicacion: 'Av. 1',
      estado: 'en_ejecucion',
      avance_pct: '68.00',
      meta: 'Meta',
      monto_asignado: 1000,
      monto_ejecutado: '680',
      fotos: 2,
      publicada: true,
      inicio: '2026-01-01',
      actualizada_en: '2026-11-01',
      porcentaje_tributos: null,
      hitos: ['Excavación', 'Cimientos'],
      latitud: -12.08,
      longitud: -77.03,
    });
    expect(o.avancePct).toBe(68);
    expect(o.hitos).toEqual(['Excavación', 'Cimientos']);
    expect(o.porcentajeTributos).toBeNull();
    expect(o.latitud).toBe(-12.08);
  });
});
