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
  ETIQUETA_TIPO_RECLAMO,
  etiquetaPlazo,
  fechaLimitePlazo,
  formatearDiaMes,
  formatearFecha,
  formatearFechaCorta,
  formatearHora,
  formatearSoles,
  momentoAviso,
  nombreDistrito,
  sumarDeudas,
  deudasPendientes,
  textoVencimiento,
} from './formato';
import { colors, sizes, spacing } from './tokens';
import {
  avisosRecibidos,
  mensajeAviso,
  obraParaAvisos,
  tipoAvisoActual,
  tituloAviso,
} from './avisos';
import {
  bienvenidaAsistente,
  deudasASimular,
  PREGUNTAS_SUGERIDAS,
  RESPUESTA_SIN_REGLA,
  responderAsistente,
  simularCuotas,
} from './asistente';
import {
  AREA_TIPO_RECLAMO,
  clasificarReclamo,
  pasosSeguimiento,
  plazoReclamo,
  siguienteCodigoReclamo,
  TIPOS_RECLAMO,
  tituloReclamo,
} from './reclamos';

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

describe('avisos', () => {
  const deRosa = recordatorios.filter((aviso) => aviso.vecinoId === 'v-rosa-li');
  const deudasDeRosa = deudas.filter((deuda) => deuda.vecinoId === 'v-rosa-li');
  const arbitrios = deudas.find((deuda) => deuda.id === 'd-arbitrios-4t')!;
  const multa = deudas.find((deuda) => deuda.id === 'd-multa')!;
  const obra = obraParaAvisos(obras.filter((fila) => fila.municipalidadId === 'm-lince'));

  it('escribe el día y la hora de cada aviso como el prototipo', () => {
    expect(formatearDiaMes('2026-11-30')).toBe('30 de noviembre');
    expect(momentoAviso('2026-10-31T10:15:00-05:00', HOY_EJEMPLO)).toBe('Ayer, 10:15 h');
    expect(momentoAviso('2026-10-24T09:02:00-05:00', HOY_EJEMPLO)).toBe('24 oct, 9:02 h');
    expect(momentoAviso('2026-11-01T08:00:00-05:00', HOY_EJEMPLO)).toBe('Hoy, 8:00 h');
    expect(momentoAviso('2025-12-24T09:02:00-05:00', HOY_EJEMPLO)).toBe('24 dic 2025, 9:02 h');
  });

  it('lista los avisos recibidos del más nuevo al más antiguo, con sus títulos', () => {
    const lista = avisosRecibidos(deRosa).map((aviso) => {
      const deuda = deudas.find((fila) => fila.id === aviso.deudaId)!;
      return tituloAviso(aviso.tipo, deuda);
    });
    expect(lista).toEqual(['Tu arbitrio vence pronto', 'Tu multa está en mora']);
  });

  it('ubica a la vecina en el aviso más alto de una deuda pendiente', () => {
    expect(tipoAvisoActual(deRosa, deudasDeRosa)).toBe('mora');
    const multaPagada = deudasDeRosa.map((deuda) =>
      deuda.id === 'd-multa' ? { ...deuda, estado: 'pagada' as const } : deuda,
    );
    expect(tipoAvisoActual(deRosa, multaPagada)).toBe('preventivo');
    expect(tipoAvisoActual([], deudasDeRosa)).toBeNull();
  });

  it('menciona la obra por su nombre corto', () => {
    expect(obra?.nombreCorto).toBe('parque Castilla');
  });

  it('arma los mensajes con los textos del prototipo', () => {
    expect(mensajeAviso({ tipo: 'preventivo', deuda: arbitrios, nombre: 'Rosa', obra })).toBe(
      'Hola, Rosa. Tus arbitrios de S/ 80.50 vencen el 30 de noviembre. Pagar a tiempo te evita intereses, y tu aporte financia obras como el parque Castilla.',
    );
    expect(
      mensajeAviso({ tipo: 'preventivo', deuda: arbitrios, nombre: 'Rosa', obra, version: 'ejemplo' }),
    ).toBe(
      'Hola, Rosa. Tus arbitrios de S/ 80.50 vencen el 30 de noviembre. Pagar a tiempo te evita intereses. Tu aporte financia obras como el parque Castilla.',
    );
    expect(mensajeAviso({ tipo: 'mora', deuda: multa, nombre: 'Rosa' })).toBe(
      'Rosa, tu multa administrativa de S/ 40.00 venció el 15 de octubre. Puedes pagar en la app o simular cuotas. ¿Dudas? Responde a este mensaje.',
    );
    expect(mensajeAviso({ tipo: 'previo_coactiva', deuda: multa, nombre: 'Rosa' })).toBe(
      'Rosa, tu multa podría pasar a cobranza coactiva, a cargo de la municipalidad. Aún puedes pagar o pedir orientación. Si ya reclamaste, este aviso es solo informativo.',
    );
  });

  it('omite la frase de la obra si no tiene nombre corto', () => {
    expect(
      mensajeAviso({
        tipo: 'preventivo',
        deuda: arbitrios,
        nombre: 'Rosa',
        obra: { nombreCorto: null },
      }),
    ).toBe(
      'Hola, Rosa. Tus arbitrios de S/ 80.50 vencen el 30 de noviembre. Pagar a tiempo te evita intereses.',
    );
  });
});

describe('asistente', () => {
  const deudasDeRosa = deudas.filter((deuda) => deuda.vecinoId === 'v-rosa-li');
  const sinPendientes = deudasDeRosa.map((deuda) => ({ ...deuda, estado: 'pagada' as const }));

  it('saluda con el texto del prototipo', () => {
    expect(bienvenidaAsistente('Rosa')).toBe(
      'Hola, Rosa. Soy el asistente de Almira. Puedo explicarte tus deudas y simular cuotas. Yo oriento: la decisión es de la municipalidad.',
    );
  });

  it('responde las preguntas sugeridas con reglas fijas', () => {
    expect(responderAsistente(PREGUNTAS_SUGERIDAS[0], deudasDeRosa)).toEqual({
      texto: 'Puedo simular cuotas con los beneficios vigentes. La decisión es de la municipalidad.',
      accion: 'simular_cuotas',
    });
    const multa = responderAsistente(PREGUNTAS_SUGERIDAS[1], deudasDeRosa);
    expect(multa.texto).toContain(`Multa administrativa de ${formatearSoles(40)}`);
    expect(multa.texto).toContain('15 de octubre de 2026');
    expect(multa.texto).toContain('La decisión es de la municipalidad.');
    expect(multa.accion).toBeUndefined();
  });

  it('entiende variantes sin tildes y orienta cuando no hay regla', () => {
    expect(responderAsistente('quiero FRACCIONAR', deudasDeRosa).accion).toBe('simular_cuotas');
    expect(responderAsistente('¿cuál es el horario?', deudasDeRosa).texto).toBe(RESPUESTA_SIN_REGLA);
  });

  it('no ofrece simular si no hay deudas pendientes', () => {
    expect(responderAsistente('cuotas', sinPendientes).accion).toBeUndefined();
    expect(responderAsistente('multa', sinPendientes).texto).toBe(
      'No tienes multas pendientes en esta municipalidad.',
    );
  });

  it('elige las deudas según el alcance de la simulación', () => {
    expect(sumarDeudas(deudasASimular(deudasDeRosa, 'toda'))).toBe(120.5);
    expect(sumarDeudas(deudasASimular(deudasDeRosa, 'mora'))).toBe(40);
  });

  it('reproduce la simulación del prototipo con la tasa ilustrativa', () => {
    expect(simularCuotas(deudasASimular(deudasDeRosa, 'toda'), 6)).toEqual({
      deuda: 120.5,
      cuotas: 6,
      cuotaMensual: 20.79,
      interes: 4.25,
      total: 124.75,
    });
    expect(simularCuotas(deudasASimular(deudasDeRosa, 'mora'), 4, 0).cuotaMensual).toBe(10);
  });
});

describe('reclamos', () => {
  const deRosa = reclamos.filter((reclamo) => reclamo.vecinoId === 'v-rosa-li');
  const poste = reclamos.find((reclamo) => reclamo.codigo === 'R-01842')!;

  it('clasifica con reglas fijas y deja "otro" si no reconoce nada', () => {
    expect(
      clasificarReclamo('Hay un bache grande en la pista frente a mi casa, los carros lo esquivan.'),
    ).toBe('pistas_veredas');
    expect(clasificarReclamo(poste.descripcion!)).toBe('alumbrado');
    expect(clasificarReclamo('Un auto bloquea la rampa de mi cochera')).toBe(
      'vehiculo_mal_estacionado',
    );
    expect(clasificarReclamo('Me cobraron dos veces')).toBe('cobro_indebido');
    expect(clasificarReclamo('Ruidos fuertes de noche')).toBe('otro');
  });

  it('asigna las áreas que usan los datos de ejemplo', () => {
    for (const reclamo of reclamos) {
      expect(AREA_TIPO_RECLAMO[reclamo.tipo]).toBe(reclamo.area);
    }
    expect(TIPOS_RECLAMO).toEqual(Object.keys(ETIQUETA_TIPO_RECLAMO));
  });

  it('sigue el correlativo de la municipalidad', () => {
    expect(siguienteCodigoReclamo(reclamos)).toBe('R-01867');
    expect(siguienteCodigoReclamo([])).toBe('R-00001');
  });

  it('arma un título corto con la primera frase', () => {
    expect(tituloReclamo('Hay un bache grande en la pista frente a mi casa, los carros lo esquivan.')).toBe(
      'Hay un bache grande en la pista frente a…',
    );
    expect(tituloReclamo('poste sin luz. Desde ayer')).toBe('Poste sin luz');
  });

  it('calcula el plazo del prototipo: quedan 3 de 10 días hábiles', () => {
    expect(plazoReclamo(poste, HOY_EJEMPLO)).toEqual({ etiqueta: 'Quedan 3 d', quedan: 3, total: 10 });
    expect(plazoReclamo(deRosa.find((r) => r.estado === 'resuelto')!, HOY_EJEMPLO)).toBeNull();
    const nuevo = { estado: 'derivado' as const, creadoEn: HOY_EJEMPLO, plazoDias: 10, plazo: null };
    expect(plazoReclamo(nuevo, HOY_EJEMPLO)?.quedan).toBe(10);
  });

  it('marca el paso en curso del seguimiento', () => {
    const estados = (estado: Parameters<typeof pasosSeguimiento>[0]) =>
      pasosSeguimiento(estado).map((paso) => paso.estado);
    expect(estados('en_atencion')).toEqual(['hecho', 'hecho', 'hecho', 'actual', 'pendiente']);
    expect(estados('derivado')).toEqual(['hecho', 'hecho', 'actual', 'pendiente', 'pendiente']);
    expect(estados('resuelto')).toEqual(['hecho', 'hecho', 'hecho', 'hecho', 'hecho']);
  });
});
