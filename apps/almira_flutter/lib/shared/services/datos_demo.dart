import '../models/modelos.dart';

/// Registros del modo demostración. Son ficticios: salen de los datos de
/// ejemplo del repo (`packages/shared/src/datos-ejemplo.ts`) y la app los
/// muestra siempre con la etiqueta «Demostración». Las fechas se calculan
/// desde hoy para que los vencimientos y plazos tengan sentido cualquier día.
abstract final class DatosDemo {
  static const usuarioId = 'demo-usuario';
  static const vecinoId = 'demo-vecino';
  static const municipalidadId = 'demo-lince';
  static const _otraMunicipalidadId = 'demo-villa-verde';
  static const _predioId = 'demo-predio';

  /// Código y DNI que el padrón de demostración acepta al vincular.
  static const codigoContribuyente = '0048217';
  static const dni = '40000082';

  static FuenteDatos crear(DateTime hoy) {
    DateTime dias(int n) => DateTime(hoy.year, hoy.month, hoy.day).add(Duration(days: n));
    final anio = hoy.year;

    return FuenteDatos(
      municipalidades: const [
        Municipalidad(
          id: municipalidadId,
          nombre: 'Municipalidad de Lince',
          zona: 'Lima Centro',
          urlPago: 'https://consultas.munilince.gob.pe/pagosenlinea/',
        ),
        Municipalidad(
          id: _otraMunicipalidadId,
          nombre: 'Municipalidad de Villa Verde',
          zona: 'Lima Sur',
        ),
      ],
      vecinos: const [
        Vecino(
          id: vecinoId,
          municipalidadId: municipalidadId,
          userId: usuarioId,
          nombre: 'Rosa Quispe Huamán',
          codigoContribuyente: codigoContribuyente,
          canalPreferido: CanalAviso.whatsapp,
        ),
      ],
      predios: const [
        Predio(
          id: _predioId,
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          codigo: 'PR-0048217',
          direccion: 'Jr. Bernardo Alcedo 480, Lince',
        ),
      ],
      deudas: [
        Deuda(
          id: 'demo-multa',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          tipo: TipoDeuda.multa,
          concepto: 'Multa administrativa',
          periodo: 'Fiscalización · $anio',
          montoInsoluto: 40,
          interesMoratorio: 0,
          vencimiento: dias(-27),
          estado: EstadoDeuda.vencida,
        ),
        Deuda(
          id: 'demo-arbitrios',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          predioId: _predioId,
          tipo: TipoDeuda.arbitrios,
          concepto: 'Arbitrios',
          periodo: 'Trimestre en curso · Limpieza, parques y serenazgo',
          montoInsoluto: 80.5,
          interesMoratorio: 0,
          vencimiento: dias(19),
          estado: EstadoDeuda.vigente,
        ),
        Deuda(
          id: 'demo-predial',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          predioId: _predioId,
          tipo: TipoDeuda.predial,
          concepto: 'Impuesto predial',
          periodo: '4.ª cuota $anio',
          montoInsoluto: 186.4,
          interesMoratorio: 0,
          vencimiento: dias(19),
          estado: EstadoDeuda.pagada,
        ),
        Deuda(
          id: 'demo-arbitrios-anterior',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          predioId: _predioId,
          tipo: TipoDeuda.arbitrios,
          concepto: 'Arbitrios',
          periodo: 'Trimestre anterior',
          montoInsoluto: 78,
          interesMoratorio: 0,
          vencimiento: dias(-72),
          estado: EstadoDeuda.pagada,
        ),
      ],
      pagos: [
        Pago(
          id: 'demo-pago-1',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          deudaId: 'demo-predial',
          monto: 186.4,
          estado: EstadoPago.confirmado,
          referencia: 'OP-77120',
          creadoEn: dias(-14),
        ),
        Pago(
          id: 'demo-pago-2',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          deudaId: 'demo-arbitrios-anterior',
          monto: 78,
          estado: EstadoPago.confirmado,
          referencia: 'OP-70318',
          creadoEn: dias(-75),
        ),
      ],
      recordatorios: [
        Recordatorio(
          id: 'demo-aviso-1',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          deudaId: 'demo-arbitrios',
          tipo: TipoRecordatorio.preventivo,
          canal: CanalAviso.whatsapp,
          estado: 'entregado',
          programadoPara: dias(-1).add(const Duration(hours: 10, minutes: 15)),
          entregadoEn: dias(-1).add(const Duration(hours: 10, minutes: 15)),
        ),
        Recordatorio(
          id: 'demo-aviso-2',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          deudaId: 'demo-multa',
          tipo: TipoRecordatorio.mora,
          canal: CanalAviso.whatsapp,
          estado: 'entregado',
          programadoPara: dias(-18).add(const Duration(hours: 9, minutes: 2)),
          entregadoEn: dias(-18).add(const Duration(hours: 9, minutes: 2)),
        ),
      ],
      reclamos: [
        Reclamo(
          id: 'demo-reclamo-1842',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          codigo: 'R-01842',
          tipo: TipoReclamo.alumbrado,
          titulo: 'Poste sin luz en la esquina',
          descripcion:
              'El poste de la esquina lleva una semana apagado y la cuadra queda muy oscura.',
          estado: EstadoReclamo.enAtencion,
          area: 'Obras',
          direccion: 'Jr. Pumacahua 1450',
          latitud: -12.0852,
          longitud: -77.0431,
          plazoDias: 10,
          creadoEn: dias(-6),
        ),
        Reclamo(
          id: 'demo-reclamo-1790',
          municipalidadId: municipalidadId,
          vecinoId: vecinoId,
          codigo: 'R-01790',
          tipo: TipoReclamo.pistasVeredas,
          titulo: 'Bache en la pista',
          descripcion: 'Bache profundo frente al paradero, los autos lo esquivan.',
          estado: EstadoReclamo.resuelto,
          area: 'Obras',
          direccion: 'Av. Ignacio Merino, cdra. 18',
          plazoDias: 10,
          creadoEn: dias(-36),
        ),
      ],
      obras: [
        Obra(
          id: 'demo-obra-pistas',
          municipalidadId: municipalidadId,
          nombre: 'Mantenimiento de pistas',
          ubicacion: 'Av. Ignacio Merino, cdras. 17-19',
          estado: EstadoObra.finalizada,
          avancePct: 100,
          meta: 'Concluida',
          montoAsignado: 680000,
          montoEjecutado: 680000,
          publicada: true,
          actualizadaEn: dias(-13),
          latitud: -12.0826,
          longitud: -77.0329,
        ),
        Obra(
          id: 'demo-obra-parque',
          municipalidadId: municipalidadId,
          nombre: 'Renovación del parque Castilla',
          nombreCorto: 'parque Castilla',
          ubicacion: 'Parque Castilla, Zona 3',
          estado: EstadoObra.enEjecucion,
          avancePct: 68,
          meta: 'Entrega prevista: febrero ${anio + 1}',
          montoAsignado: 920000,
          montoEjecutado: 610000,
          publicada: true,
          inicio: dias(-160),
          actualizadaEn: dias(-16),
          porcentajeTributos: 62,
          hitos: const ['Riego y áreas verdes: 80 %', 'Juegos y luminarias: en curso'],
          latitud: -12.0886,
          longitud: -77.0414,
        ),
        Obra(
          id: 'demo-obra-veredas',
          municipalidadId: municipalidadId,
          nombre: 'Veredas accesibles',
          ubicacion: 'Av. Risso, cdras. 3-7',
          estado: EstadoObra.enEjecucion,
          avancePct: 34,
          meta: 'Entrega prevista: marzo ${anio + 1}',
          montoAsignado: 410000,
          montoEjecutado: 139400,
          publicada: true,
          actualizadaEn: dias(-28),
          latitud: -12.0852,
          longitud: -77.0309,
        ),
      ],
    );
  }
}
