import { describe, expect, it } from 'vitest';
import solesFunciones from '../../../supabase/functions/_shared/soles.ts?raw';
import solesCompartido from './soles.ts?raw';
import {
  CENTRO_MAPA_LIMA,
  coloresMapa,
  encuadreMapa,
  htmlMapaObras,
  leerMensajeDelMapa,
  MAPA_ATRIBUCION,
  MAPA_ATRIBUCION_URL,
  obrasConUbicacion,
} from './mapa';
import {
  centroMapaDe,
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
  formatearNumero,
  formatearPorcentaje,
  formatearSoles,
  formatearVariacion,
  haceDias,
  iniciales,
  momentoAviso,
  nombreDistrito,
  sumarDeudas,
  deudasPendientes,
  textoVencimiento,
} from './formato';
import { colors, fontFamily, panelSizes, sizes, spacing, typography } from './tokens';
import { mejorVariante, panelEjemplo, superaUmbral } from './panel-ejemplo';
import {
  alternarCanal,
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
import {
  deudasSeleccionadas,
  proximoVencimiento,
  repartoDeuda,
  totalSeleccionado,
} from './pagos';
import { codigoValido, documentoValido } from './ingreso';

describe('tokens', () => {
  it('aplica los colores de la guía turquesa', () => {
    expect(colors.primary).toBe('#0B7F86');
    expect(colors.primaryPressed).toBe('#00646A');
    expect(colors.primaryDisabled).toBe('#A9D2D4');
    expect(colors.accent).toBe('#2CC5C0');
    expect(colors.highlight).toBe('#E3F6F5');
    expect(colors.subtle).toBe('#F2F8F8');
    expect(colors.background).toBe('#FFFFFF');
    expect(colors.surface).toBe('#FFFFFF');
    expect(colors.panelBackground).toBe('#F7FAFA');
    expect(colors.text).toBe('#0F2A2E');
    expect(colors.textSecondary).toBe('#5B6B70');
    expect(colors.border).toBe('#D6E3E4');
    expect(colors.track).toBe('#E6EFF0');
  });

  it('usa colores de estado con texto legible sobre su fondo suave', () => {
    expect([colors.success, colors.successSoft, colors.successText]).toEqual([
      '#2E9E6B',
      '#EAF6F0',
      '#1F7A50',
    ]);
    expect([colors.warning, colors.warningSoft, colors.warningText]).toEqual([
      '#C98A00',
      '#FBF5E6',
      '#8A5E00',
    ]);
    expect([colors.danger, colors.dangerSoft, colors.dangerText]).toEqual([
      '#D64545',
      '#FAEAEA',
      '#B42F2F',
    ]);
  });

  it('usa las medidas de la guía turquesa', () => {
    expect(sizes.button).toBe(52);
    expect(sizes.buttonTertiary).toBe(48);
    expect(sizes.input).toBe(52);
    expect(sizes.headerBar).toBe(56);
    expect(sizes.tabBar).toBe(64);
    expect(spacing.margin).toBe(20);
    expect(spacing.block).toBe(16);
  });

  it('escribe con Inter y cifras legibles para adultos mayores', () => {
    expect(fontFamily).toBe('Inter');
    expect(typography.bodyMd.fontSize).toBeGreaterThanOrEqual(14);
    expect(typography.bodyLg.fontSize).toBe(16);
    expect(typography.tabLabel).toMatchObject({ fontSize: 11, lineHeight: 14 });
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
  it('prende y apaga canales sin dejar ninguno vacío', () => {
    expect(alternarCanal(['whatsapp'], 'sms')).toEqual(['whatsapp', 'sms']);
    expect(alternarCanal(['app'], 'whatsapp')).toEqual(['whatsapp', 'app']);
    expect(alternarCanal(['whatsapp', 'sms'], 'whatsapp')).toEqual(['sms']);
    expect(alternarCanal(['sms'], 'sms')).toEqual(['sms']);
  });

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

describe('obras y perfil', () => {
  it('dice cuántos días pasaron desde la última actualización', () => {
    expect(haceDias('2026-10-26', HOY_EJEMPLO)).toBe('hace 6 días');
    expect(haceDias('2026-10-31', HOY_EJEMPLO)).toBe('hace 1 día');
    expect(haceDias(HOY_EJEMPLO, HOY_EJEMPLO)).toBe('hoy');
  });

  it('arma las iniciales con el nombre y el apellido paterno', () => {
    expect(iniciales('Rosa Quispe Huamán')).toBe('RQ');
    expect(iniciales('María Ejemplo')).toBe('ME');
    expect(iniciales('Ana María Rojas Paz')).toBe('AR');
  });
});

describe('panel municipal', () => {
  const panel = panelEjemplo('m-lince')!;

  it('escribe los montos y cifras del panel como el prototipo', () => {
    expect(formatearSoles(1120400, { sinDecimales: true })).toBe('S/ 1,120,400');
    expect(formatearSoles(312000, { enMiles: true })).toBe('S/ 312 mil');
    expect(formatearNumero(18420)).toBe('18,420');
    expect(formatearNumero(1.42)).toBe('1.42');
    expect(formatearPorcentaje(62)).toBe('62 %');
    expect(formatearVariacion(7.7)).toBe('+7.7 %');
    expect(formatearVariacion(-18)).toBe('−18 %');
  });

  it('trae las cifras de Lince del prototipo y ninguna de otras municipalidades', () => {
    expect(panel.recaudacion.mes).toBe(1120400);
    expect(panel.pagosATiempo).toEqual({ porcentaje: 62, puntos: 9, meta: 70 });
    expect(panel.recaudacionMensual.map((mes) => mes.millones)).toEqual([
      1.42, 0.96, 1.01, 1.38, 1.04, 1.12,
    ]);
    expect(panelEjemplo('m-villa-verde')).toBeUndefined();
  });

  it('ordena los reclamos por área de mayor a menor', () => {
    const cantidades = panel.reclamosPorArea.map((fila) => fila.cantidad);
    expect(cantidades).toEqual([...cantidades].sort((a, b) => b - a));
  });

  it('calcula la ventaja de la mejor variante de la prueba A/B', () => {
    expect(mejorVariante(panel.pruebaAB.variantes)).toEqual({ letra: 'B', puntos: 6 });
  });

  it('deja tres casos en cola humana con 40 minutos de espera máxima', () => {
    const enCola = panel.casos.filter((caso) => caso.estado === 'en_cola');
    expect(enCola).toHaveLength(3);
    expect(Math.max(...enCola.map((caso) => caso.esperaMinutos ?? 0))).toBe(40);
  });

  it('usa las medidas del panel web del prototipo', () => {
    expect(panelSizes.sidebar).toBe(248);
    expect(panelSizes.navItem).toBe(36);
  });
});

describe('panel: recaudación, avisos y reclamos', () => {
  const panel = panelEjemplo('m-lince')!;

  it('cuadra los avisos por canal y por escalera con el total del mes', () => {
    const porCanal = panel.canales.reduce((suma, canal) => suma + canal.cantidad, 0);
    const porEscalera = panel.escalera.reduce((suma, paso) => suma + paso.enviados, 0);
    expect(porCanal).toBe(panel.avisos.total);
    expect(porEscalera).toBe(panel.avisos.total);
  });

  it('cuadra la recaudación por zona, en miles, con la del mes', () => {
    const miles = panel.recaudacionPorZona.reduce((suma, zona) => suma + zona.soles, 0) / 1000;
    expect(miles).toBe(Math.round(panel.recaudacion.mes / 1000));
  });

  it('da zona a cada reclamo de ejemplo de la municipalidad', () => {
    const propios = reclamos.filter((reclamo) => reclamo.municipalidadId === 'm-lince');
    expect(propios.every((reclamo) => panel.zonaReclamo[reclamo.codigo])).toBe(true);
  });

  it('calcula los plazos de web-05 desde el hoy del prototipo', () => {
    const etiqueta = (codigo: string) =>
      plazoReclamo(reclamos.find((r) => r.codigo === codigo)!, HOY_EJEMPLO)?.etiqueta;
    expect(etiqueta('R-01851')).toBe('Vencido 2 d');
    expect(etiqueta('R-01842')).toBe('Quedan 3 d');
    expect(etiqueta('R-01866')).toBe('Quedan 8 d');
    expect(etiqueta('R-01790')).toBeUndefined();
  });
});

describe('panel: atención, alertas y accesos', () => {
  const panel = panelEjemplo('m-lince')!;

  it('dispara una alerta por cada umbral superado', () => {
    const superados = panel.umbrales.filter(superaUmbral).map((umbral) => umbral.evento);
    expect(superados).toEqual(['Respuestas graves del asistente']);
    expect(panel.alertasActivas).toHaveLength(superados.length);
  });

  it('enlaza el registro de accesos con reclamos y casos de ejemplo', () => {
    expect(reclamos.some((reclamo) => reclamo.codigo === 'R-01851')).toBe(true);
    expect(panel.casos.some((caso) => caso.codigo === 'H-205')).toBe(true);
  });

  it('deja la cola por debajo del umbral de alerta', () => {
    const enCola = panel.casos.filter((caso) => caso.estado === 'en_cola').length;
    expect(enCola).toBeLessThan(panel.atencion.umbralCola);
  });

  it('marca en rojo solo la espera larga y un solo paso del incidente', () => {
    const largas = panel.casos.filter(
      (caso) => (caso.esperaMinutos ?? 0) >= panel.atencion.esperaLargaMinutos,
    );
    expect(largas.map((caso) => caso.codigo)).toEqual(['H-209']);
    expect(panel.rutaIncidente.filter((paso) => paso.alerta)).toHaveLength(1);
  });

  it('llama "Asistente" al asistente, sin "IA"', () => {
    const textos = [
      ...panel.casos.map((caso) => caso.origen),
      ...panel.umbrales.map((umbral) => umbral.evento),
      ...panel.auditoria.map((fila) => fila.nombre),
      ...panel.registroAccesos.map((acceso) => acceso.accion),
    ];
    expect(textos.filter((texto) => /\bIA\b/.test(texto))).toEqual([]);
  });
});

describe('pagar', () => {
  const deRosa = deudas.filter((deuda) => deuda.vecinoId === 'v-rosa-li');

  it('suma solo las deudas pendientes marcadas', () => {
    const todas = deRosa.map((deuda) => deuda.id);
    expect(deudasSeleccionadas(deRosa, todas).map((deuda) => deuda.id)).toEqual([
      'd-multa',
      'd-arbitrios-4t',
    ]);
    expect(totalSeleccionado(deRosa, todas)).toBeCloseTo(120.5);
    expect(totalSeleccionado(deRosa, ['d-arbitrios-4t'])).toBeCloseTo(80.5);
    expect(totalSeleccionado(deRosa, [])).toBe(0);
  });

  it('ignora ids pagados o de otra municipalidad', () => {
    expect(totalSeleccionado(deRosa, ['d-predial-4c', 'd-arbitrios-vv'])).toBe(0);
  });

  it('reparte la deuda de Rosa entre en mora y por vencer', () => {
    expect(repartoDeuda(deRosa)).toEqual({
      total: 120.5,
      cantidad: 2,
      enMora: 40,
      porVencer: 80.5,
      porcentajeEnMora: 33,
      porcentajePorVencer: 67,
    });
  });

  it('reparte en cero cuando no hay deuda pendiente', () => {
    const pagadas = deRosa.filter((deuda) => deuda.estado === 'pagada');
    expect(repartoDeuda(pagadas)).toMatchObject({
      total: 0,
      cantidad: 0,
      porcentajeEnMora: 0,
      porcentajePorVencer: 0,
    });
  });

  it('busca el próximo vencimiento desde hoy, sin contar los ya vencidos', () => {
    expect(proximoVencimiento(deRosa, HOY_EJEMPLO)).toBe('2026-11-30');
    expect(proximoVencimiento(deRosa, '2026-11-30')).toBe('2026-11-30');
    expect(proximoVencimiento(deRosa, '2026-12-01')).toBeNull();
    expect(proximoVencimiento([], HOY_EJEMPLO)).toBeNull();
  });
});

describe('ingreso', () => {
  it('acepta DNI o carné de 8 a 12 letras o números', () => {
    expect(documentoValido('40000082')).toBe(true);
    expect(documentoValido(' 40000082 ')).toBe(true);
    expect(documentoValido('CE0012345678')).toBe(true);
    expect(documentoValido('4000008')).toBe(false);
    expect(documentoValido('CE00123456789')).toBe(false);
    expect(documentoValido('40••••82')).toBe(false);
    expect(documentoValido('4000 0082')).toBe(false);
  });

  it('acepta cualquier código de 6 dígitos', () => {
    expect(codigoValido(USUARIO_EJEMPLO.codigoSmsEjemplo)).toBe(true);
    expect(codigoValido('000000')).toBe(true);
    expect(codigoValido('48217')).toBe(false);
    expect(codigoValido('4821755')).toBe(false);
    expect(codigoValido('48a175')).toBe(false);
  });
});

describe('mapa de obras', () => {
  const colores = coloresMapa(colors);
  const deLince = obras.filter((obra) => obra.municipalidadId === 'm-lince');
  const centroLince = centroMapaDe('m-lince');

  it('deja en el mapa solo las obras publicadas con coordenadas', () => {
    const sinPunto = { ...deLince[0]!, id: 'sin-punto', latitud: null, longitud: null };
    const ids = obrasConUbicacion([...deLince, sinPunto]).map((obra) => obra.id);
    expect(ids).toEqual(['o-pistas-merino', 'o-parque-castilla', 'o-veredas-risso']);
    expect(ids).not.toContain('o-luminarias-led');
    expect(ids).not.toContain('sin-punto');
  });

  it('sin puntos se centra en el distrito', () => {
    expect(encuadreMapa([], centroLince)).toEqual({
      tipo: 'centro',
      centro: [centroLince.latitud, centroLince.longitud],
      zoom: centroLince.zoom,
    });
    expect(centroMapaDe('no-existe')).toBe(CENTRO_MAPA_LIMA);
  });

  it('con un punto lo encierra con margen', () => {
    const encuadre = encuadreMapa([{ latitud: -12.08, longitud: -77.03 }], centroLince);
    expect(encuadre.tipo).toBe('limites');
    if (encuadre.tipo !== 'limites') return;
    const [[sur, oeste], [norte, este]] = encuadre.limites;
    expect(sur).toBeLessThan(-12.08);
    expect(norte).toBeGreaterThan(-12.08);
    expect(oeste).toBeLessThan(-77.03);
    expect(este).toBeGreaterThan(-77.03);
    expect(norte - sur).toBeCloseTo(este - oeste);
  });

  it('con varios puntos los encierra a todos con margen', () => {
    const puntos = obrasConUbicacion(deLince);
    const encuadre = encuadreMapa(puntos, centroLince);
    expect(encuadre.tipo).toBe('limites');
    if (encuadre.tipo !== 'limites') return;
    const [[sur, oeste], [norte, este]] = encuadre.limites;
    for (const punto of puntos) {
      expect(punto.latitud).toBeGreaterThan(sur);
      expect(punto.latitud).toBeLessThan(norte);
      expect(punto.longitud).toBeGreaterThan(oeste);
      expect(punto.longitud).toBeLessThan(este);
    }
    expect(sur).toBeLessThan(Math.min(...puntos.map((p) => p.latitud)));
  });

  it('arma el HTML con la atribución y sin obras no publicadas', () => {
    const html = htmlMapaObras({
      obras: deLince,
      interactivo: true,
      colores,
      centroPorDefecto: centroLince,
    });
    expect(html).toContain(MAPA_ATRIBUCION);
    expect(html).toContain(MAPA_ATRIBUCION_URL);
    expect(html).toContain('leaflet@1.9.4/dist/leaflet.js');
    expect(html).toContain('integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="');
    expect(html).toContain('o-parque-castilla');
    expect(html).not.toContain('o-luminarias-led');
    expect(html).not.toContain('Luminarias LED');
  });

  it('solo usa los colores que recibe', () => {
    const html = htmlMapaObras({ obras: deLince, interactivo: false, colores, centroPorDefecto: centroLince });
    const hex = new Set(html.match(/#[0-9A-Fa-f]{6}\b/g) ?? []);
    const permitidos = new Set(Object.values(colores));
    for (const valor of hex) expect(permitidos).toContain(valor);
  });

  it('no deja cerrar el script con el nombre de una obra', () => {
    const peligrosa = { ...deLince[1]!, nombre: '</script><script>alert(1)</script>' };
    const html = htmlMapaObras({ obras: [peligrosa], interactivo: true, colores, centroPorDefecto: centroLince });
    expect(html).not.toContain('</script><script>alert(1)');
  });

  it('no deja cerrar el script con el id de una obra', () => {
    const peligrosa = { ...deLince[1]!, id: '</script>' };
    const html = htmlMapaObras({ obras: [peligrosa], interactivo: false, colores, centroPorDefecto: centroLince });
    expect(html).not.toContain('"id":"</script>"');
    expect([...html.matchAll(/<\/script>/g)]).toHaveLength(3);
  });

  it('arma JavaScript válido en el HTML', () => {
    const html = htmlMapaObras({
      obras: deLince,
      seleccionadaId: 'o-parque-castilla',
      interactivo: true,
      colores,
      centroPorDefecto: centroLince,
      ubicacion: { latitud: -12.0844, longitud: -77.0315 },
    });
    const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]!);
    expect(scripts).toHaveLength(2);
    for (const codigo of scripts) expect(() => new Function(codigo)).not.toThrow();
  });

  it('lee solo mensajes conocidos del mapa', () => {
    expect(leerMensajeDelMapa({ tipo: 'obra', id: 'o-1' })).toEqual({ tipo: 'obra', id: 'o-1' });
    expect(leerMensajeDelMapa('{"tipo":"error"}')).toEqual({ tipo: 'error' });
    expect(leerMensajeDelMapa({ tipo: 'listo' })).toEqual({ tipo: 'listo' });
    expect(leerMensajeDelMapa({ tipo: 'otro' })).toBeNull();
    expect(leerMensajeDelMapa({ tipo: 'obra', id: 3 })).toBeNull();
    expect(leerMensajeDelMapa('no es json')).toBeNull();
    expect(leerMensajeDelMapa(null)).toBeNull();
  });
});

describe('copia de soles.ts en las Edge Functions', () => {
  it('coincide con packages/shared/src/soles.ts, salvo el comentario inicial', () => {
    const sinComentario = (texto: string) => texto.replace(/^(\/\/[^\n]*\n)+/, '');
    expect(sinComentario(solesFunciones)).toBe(sinComentario(solesCompartido));
  });
});
