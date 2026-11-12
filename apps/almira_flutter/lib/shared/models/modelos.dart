import '../../core/utils/formato.dart';

/// Modelos de la app. Reflejan las tablas de `supabase/migrations`
/// (mismo contrato que `packages/shared/src/types.ts` y `filas.ts`).
typedef Fila = Map<String, dynamic>;

String _texto(Fila f, String c) => (f[c] ?? '').toString();
String? _textoONulo(Fila f, String c) => f[c]?.toString();
double _numero(Fila f, String c) => double.tryParse((f[c] ?? 0).toString()) ?? 0;
double? _numeroONulo(Fila f, String c) =>
    f[c] == null ? null : double.tryParse(f[c].toString());

enum CanalAviso {
  whatsapp('WhatsApp'),
  sms('SMS'),
  app('Notificación en la app');

  const CanalAviso(this.etiqueta);
  final String etiqueta;

  static CanalAviso de(String valor) =>
      values.firstWhere((c) => c.name == valor, orElse: () => CanalAviso.app);
}

enum TipoDeuda {
  predial('Predial'),
  arbitrios('Arbitrios'),
  multa('Multa'),
  coactivo('Coactivo'),
  otros('Otros');

  const TipoDeuda(this.etiqueta);
  final String etiqueta;

  static TipoDeuda de(String valor) =>
      values.firstWhere((t) => t.name == valor, orElse: () => TipoDeuda.arbitrios);
}

enum EstadoDeuda {
  vigente('Por vencer'),
  vencida('Vencida'),
  pagada('Pagada');

  const EstadoDeuda(this.etiqueta);
  final String etiqueta;

  static EstadoDeuda de(String valor) =>
      values.firstWhere((e) => e.name == valor, orElse: () => EstadoDeuda.vigente);
}

/// Medios con los que se registra un pago.
enum MedioPago {
  yape('yape', 'Yape', 'Desde tu app Yape'),
  plin('plin', 'Plin', 'Desde tu app Plin'),
  tarjeta('tarjeta', 'Tarjeta de débito o crédito', 'Visa, Mastercard o American Express'),
  bancaMovil('banca_movil', 'Banca móvil o agente', 'Desde la app de tu banco o un agente');

  const MedioPago(this.clave, this.etiqueta, this.detalle);
  final String clave;
  final String etiqueta;
  final String detalle;
}

enum EstadoPago {
  pendiente('En verificación'),
  confirmado('Confirmado'),
  rechazado('Rechazado');

  const EstadoPago(this.etiqueta);
  final String etiqueta;

  static EstadoPago de(String valor) =>
      values.firstWhere((e) => e.name == valor, orElse: () => EstadoPago.pendiente);
}

enum TipoRecordatorio {
  preventivo('Recordatorio'),
  mora('Aviso de vencimiento'),
  previoCoactiva('Aviso previo a cobranza coactiva');

  const TipoRecordatorio(this.etiqueta);
  final String etiqueta;

  static TipoRecordatorio de(String valor) => switch (valor) {
        'mora' => TipoRecordatorio.mora,
        'previo_coactiva' => TipoRecordatorio.previoCoactiva,
        _ => TipoRecordatorio.preventivo,
      };
}

enum TipoReclamo {
  pistasVeredas('pistas_veredas', 'Pistas y veredas', 'Obras'),
  alumbrado('alumbrado', 'Alumbrado público', 'Obras'),
  limpieza('limpieza', 'Limpieza pública', 'Limpieza'),
  vehiculoMalEstacionado('vehiculo_mal_estacionado', 'Vehículo mal estacionado', 'Fiscalización'),
  depositoVehicular('deposito_vehicular', 'Depósito vehicular', 'Depósito'),
  cobroIndebido('cobro_indebido', 'Cobro indebido', 'Rentas'),
  otro('otro', 'Otro', 'Atención al vecino');

  const TipoReclamo(this.clave, this.etiqueta, this.area);

  /// Valor que guarda la base.
  final String clave;
  final String etiqueta;

  /// Área que suele atender esta categoría.
  final String area;

  static TipoReclamo de(String valor) =>
      values.firstWhere((t) => t.clave == valor, orElse: () => TipoReclamo.otro);
}

enum EstadoReclamo {
  enAtencion('en_atencion', 'En atención'),
  derivado('derivado', 'Derivado'),
  resuelto('resuelto', 'Resuelto');

  const EstadoReclamo(this.clave, this.etiqueta);
  final String clave;
  final String etiqueta;

  static EstadoReclamo de(String valor) =>
      values.firstWhere((e) => e.clave == valor, orElse: () => EstadoReclamo.enAtencion);
}

enum EstadoObra {
  enEjecucion('En ejecución'),
  finalizada('Concluida');

  const EstadoObra(this.etiqueta);
  final String etiqueta;

  static EstadoObra de(String valor) =>
      valor == 'finalizada' ? EstadoObra.finalizada : EstadoObra.enEjecucion;
}

class Municipalidad {
  const Municipalidad({
    required this.id,
    required this.nombre,
    this.zona = '',
    this.telefonoAyuda,
    this.urlPago,
    this.activa = true,
  });

  final String id;
  final String nombre;
  final String zona;
  final String? telefonoAyuda;

  /// Portal oficial de pago. Almira no procesa pagos: lleva a este enlace.
  final String? urlPago;
  final bool activa;

  /// "Municipalidad de Lince" -> "Lince".
  String get distrito => nombre.replaceFirst(
        RegExp(r'^Municipalidad(\s+(Distrital|Provincial))?\s+de\s+', caseSensitive: false),
        '',
      );

  factory Municipalidad.deFila(Fila f) => Municipalidad(
        id: _texto(f, 'id'),
        nombre: _texto(f, 'nombre'),
        zona: _texto(f, 'zona'),
        telefonoAyuda: _textoONulo(f, 'telefono_ayuda'),
        urlPago: _textoONulo(f, 'url_pago'),
        activa: f['activa'] == true,
      );
}

class Vecino {
  const Vecino({
    required this.id,
    required this.municipalidadId,
    required this.userId,
    required this.nombre,
    this.codigoContribuyente,
    this.canalPreferido = CanalAviso.app,
    this.nombres,
    this.apellidos,
    this.domicilioFiscal,
    this.dni,
  });

  final String id;
  final String municipalidadId;
  final String? userId;
  final String nombre;
  final String? codigoContribuyente;
  final CanalAviso canalPreferido;
  final String? nombres;
  final String? apellidos;
  final String? domicilioFiscal;

  /// Documento del propio contribuyente: solo se usa en su estado de cuenta.
  final String? dni;

  /// "APELLIDOS NOMBRES", como figura en el estado de cuenta.
  String get nombreCompleto {
    final a = apellidos?.trim() ?? '', n = nombres?.trim() ?? '';
    return a.isEmpty && n.isEmpty ? nombre : '$a $n'.trim().toUpperCase();
  }

  Vecino conCanal(CanalAviso canal) => Vecino(
        id: id,
        municipalidadId: municipalidadId,
        userId: userId,
        nombre: nombre,
        codigoContribuyente: codigoContribuyente,
        canalPreferido: canal,
        nombres: nombres,
        apellidos: apellidos,
        domicilioFiscal: domicilioFiscal,
        dni: dni,
      );

  // El teléfono no se lee. El DNI es del propio contribuyente (las políticas RLS no dejan
  // ver el de otro) y solo aparece en su estado de cuenta.
  factory Vecino.deFila(Fila f) => Vecino(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        userId: _textoONulo(f, 'user_id'),
        nombre: _texto(f, 'nombre'),
        codigoContribuyente: _textoONulo(f, 'codigo_contribuyente'),
        canalPreferido: CanalAviso.de(_texto(f, 'canal_preferido')),
        nombres: _textoONulo(f, 'nombres'),
        apellidos: _textoONulo(f, 'apellidos'),
        domicilioFiscal: _textoONulo(f, 'domicilio_fiscal'),
        dni: _textoONulo(f, 'dni'),
      );
}

class Predio {
  const Predio({
    required this.id,
    required this.municipalidadId,
    required this.vecinoId,
    required this.codigo,
    required this.direccion,
  });

  final String id;
  final String municipalidadId;
  final String vecinoId;
  final String codigo;
  final String direccion;

  factory Predio.deFila(Fila f) => Predio(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        vecinoId: _texto(f, 'vecino_id'),
        codigo: _texto(f, 'codigo'),
        direccion: _texto(f, 'direccion'),
      );
}

class Deuda {
  const Deuda({
    required this.id,
    required this.municipalidadId,
    required this.vecinoId,
    required this.tipo,
    required this.concepto,
    required this.periodo,
    required this.montoInsoluto,
    required this.interesMoratorio,
    required this.vencimiento,
    required this.estado,
    this.predioId,
    this.anio,
    this.trimestre,
    this.fechaPago,
    this.gastosEmision = 0,
    this.interesActualizacion = 0,
    this.descuento = 0,
    this.pagosAplicados = 0,
    this.nroValor,
    this.expCoactivo,
    double? saldo,
  }) : _saldo = saldo;

  final String id;
  final String municipalidadId;
  final String vecinoId;
  final String? predioId;
  final TipoDeuda tipo;
  final String concepto;
  final String periodo;
  final double montoInsoluto;
  final double interesMoratorio;
  final DateTime? vencimiento;
  final EstadoDeuda estado;
  final int? anio;
  final int? trimestre;
  final DateTime? fechaPago;
  final double gastosEmision;
  final double interesActualizacion;
  final double descuento;
  final double pagosAplicados;
  final String? nroValor;
  final String? expCoactivo;
  final double? _saldo;

  /// Importe emitido: insoluto + gastos de emisión + intereses - descuento.
  double get importe =>
      montoInsoluto + gastosEmision + interesMoratorio + interesActualizacion - descuento;

  /// Lo que falta pagar: importe - pagos. Si la base lo calculó, se usa ese valor.
  double get saldo => _saldo ?? (estado == EstadoDeuda.pagada ? 0 : importe - pagosAplicados);

  /// Lo que se muestra: el saldo mientras está pendiente; el importe pagado, después.
  double get total => pendiente ? saldo : importe;
  bool get pendiente => estado != EstadoDeuda.pagada;

  /// Año del tributo: el de la columna o, si falta, el del vencimiento.
  int get anioTributo => anio ?? vencimiento?.year ?? 0;

  /// Estado según la fecha real: una deuda "vigente" cuyo vencimiento ya pasó
  /// se muestra como vencida aunque la base todavía no la haya actualizado.
  EstadoDeuda estadoAl(DateTime hoy) {
    if (estado == EstadoDeuda.pagada) return estado;
    final v = vencimiento;
    if (v != null && diasEntre(hoy, v) < 0) return EstadoDeuda.vencida;
    return estado;
  }

  factory Deuda.deFila(Fila f) => Deuda(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        vecinoId: _texto(f, 'vecino_id'),
        predioId: _textoONulo(f, 'predio_id'),
        tipo: TipoDeuda.de(_texto(f, 'tipo')),
        concepto: _texto(f, 'concepto'),
        periodo: _texto(f, 'periodo'),
        montoInsoluto: _numero(f, 'monto_insoluto'),
        interesMoratorio: _numero(f, 'interes_moratorio'),
        vencimiento: leerFecha(_textoONulo(f, 'vencimiento')),
        estado: EstadoDeuda.de(_texto(f, 'estado')),
        anio: _numeroONulo(f, 'anio')?.round(),
        trimestre: _numeroONulo(f, 'trimestre')?.round(),
        fechaPago: leerFecha(_textoONulo(f, 'fecha_pago')),
        gastosEmision: _numero(f, 'gastos_emision'),
        interesActualizacion: _numero(f, 'interes_actualizacion'),
        descuento: _numero(f, 'descuento'),
        pagosAplicados: _numero(f, 'pagos_aplicados'),
        nroValor: _textoONulo(f, 'nro_valor'),
        expCoactivo: _textoONulo(f, 'exp_coactivo'),
        saldo: _numeroONulo(f, 'saldo'),
      );
}

class Pago {
  const Pago({
    required this.id,
    required this.municipalidadId,
    required this.vecinoId,
    required this.deudaId,
    required this.monto,
    required this.estado,
    required this.creadoEn,
    this.referencia,
    this.medio,
  });

  final String id;
  final String municipalidadId;
  final String vecinoId;
  final String deudaId;
  final double monto;
  final EstadoPago estado;
  final String? referencia;
  final DateTime? creadoEn;

  /// yape, plin, tarjeta o banca_movil.
  final String? medio;

  String get etiquetaMedio => switch (medio) {
        'yape' => 'Yape',
        'plin' => 'Plin',
        'tarjeta' => 'Tarjeta',
        'banca_movil' => 'Banca móvil',
        _ => 'Pago',
      };

  factory Pago.deFila(Fila f) => Pago(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        vecinoId: _texto(f, 'vecino_id'),
        deudaId: _texto(f, 'deuda_id'),
        monto: _numero(f, 'monto'),
        estado: EstadoPago.de(_texto(f, 'estado')),
        referencia: _textoONulo(f, 'referencia'),
        creadoEn: leerFecha(_textoONulo(f, 'creado_en')),
        medio: _textoONulo(f, 'medio'),
      );
}

class Recordatorio {
  const Recordatorio({
    required this.id,
    required this.municipalidadId,
    required this.vecinoId,
    required this.deudaId,
    required this.tipo,
    required this.canal,
    required this.estado,
    required this.programadoPara,
    this.entregadoEn,
  });

  final String id;
  final String municipalidadId;
  final String vecinoId;
  final String deudaId;
  final TipoRecordatorio tipo;
  final CanalAviso canal;

  /// programado, enviado, entregado o fallido.
  final String estado;
  final DateTime? programadoPara;
  final DateTime? entregadoEn;

  /// Solo los avisos que salieron cuentan como recibidos.
  bool get recibido => estado == 'enviado' || estado == 'entregado';
  DateTime? get fecha => entregadoEn ?? programadoPara;

  factory Recordatorio.deFila(Fila f) => Recordatorio(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        vecinoId: _texto(f, 'vecino_id'),
        deudaId: _texto(f, 'deuda_id'),
        tipo: TipoRecordatorio.de(_texto(f, 'tipo')),
        canal: CanalAviso.de(_texto(f, 'canal')),
        estado: _texto(f, 'estado'),
        programadoPara: leerFecha(_textoONulo(f, 'programado_para')),
        entregadoEn: leerFecha(_textoONulo(f, 'entregado_en')),
      );
}

class Reclamo {
  const Reclamo({
    required this.id,
    required this.municipalidadId,
    required this.vecinoId,
    required this.codigo,
    required this.tipo,
    required this.titulo,
    required this.estado,
    required this.creadoEn,
    this.descripcion,
    this.area,
    this.fotoRuta,
    this.direccion,
    this.latitud,
    this.longitud,
    this.plazoDias,
  });

  final String id;
  final String municipalidadId;
  final String vecinoId;
  final String codigo;
  final TipoReclamo tipo;
  final String titulo;
  final String? descripcion;
  final EstadoReclamo estado;
  final String? area;

  /// Ruta en el bucket `evidencias` (o archivo local en modo demostración).
  /// Null o vacía si el reclamo no tiene fotografía.
  final String? fotoRuta;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final int? plazoDias;
  final DateTime? creadoEn;

  bool get resuelto => estado == EstadoReclamo.resuelto;
  bool get tieneFoto => fotoRuta != null && fotoRuta!.trim().isNotEmpty;

  /// Solo coordenadas válidas: nunca se centra un mapa inventado.
  bool get tieneUbicacion {
    final lat = latitud, lon = longitud;
    return lat != null && lon != null && lat.abs() <= 90 && lon.abs() <= 180 && !(lat == 0 && lon == 0);
  }

  factory Reclamo.deFila(Fila f) => Reclamo(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        vecinoId: _texto(f, 'vecino_id'),
        codigo: _texto(f, 'codigo'),
        tipo: TipoReclamo.de(_texto(f, 'tipo')),
        titulo: _texto(f, 'titulo'),
        descripcion: _textoONulo(f, 'descripcion'),
        estado: EstadoReclamo.de(_texto(f, 'estado')),
        area: _textoONulo(f, 'area'),
        fotoRuta: _textoONulo(f, 'foto_ruta'),
        direccion: _textoONulo(f, 'direccion'),
        latitud: _numeroONulo(f, 'latitud'),
        longitud: _numeroONulo(f, 'longitud'),
        plazoDias: _numeroONulo(f, 'plazo_dias')?.round(),
        creadoEn: leerFecha(_textoONulo(f, 'creado_en')),
      );

  /// Mismas claves que la tabla, para guardar los reclamos del modo demostración.
  Fila aFila() => {
        'id': id,
        'municipalidad_id': municipalidadId,
        'vecino_id': vecinoId,
        'codigo': codigo,
        'tipo': tipo.clave,
        'titulo': titulo,
        'descripcion': descripcion,
        'estado': estado.clave,
        'area': area,
        'foto_ruta': fotoRuta,
        'direccion': direccion,
        'latitud': latitud,
        'longitud': longitud,
        'plazo_dias': plazoDias,
        'creado_en': creadoEn?.toIso8601String(),
      };
}

class Obra {
  const Obra({
    required this.id,
    required this.municipalidadId,
    required this.nombre,
    required this.ubicacion,
    required this.estado,
    required this.avancePct,
    required this.meta,
    required this.montoAsignado,
    required this.montoEjecutado,
    required this.publicada,
    this.nombreCorto,
    this.inicio,
    this.actualizadaEn,
    this.porcentajeTributos,
    this.hitos = const [],
    this.latitud,
    this.longitud,
  });

  final String id;
  final String municipalidadId;
  final String nombre;
  final String? nombreCorto;
  final String ubicacion;
  final EstadoObra estado;

  /// Avance físico de la obra, de 0 a 100.
  final double avancePct;
  final String meta;
  final double montoAsignado;
  final double montoEjecutado;
  final bool publicada;
  final DateTime? inicio;
  final DateTime? actualizadaEn;
  final double? porcentajeTributos;
  final List<String> hitos;
  final double? latitud;
  final double? longitud;

  bool get tieneUbicacion => latitud != null && longitud != null;

  factory Obra.deFila(Fila f) => Obra(
        id: _texto(f, 'id'),
        municipalidadId: _texto(f, 'municipalidad_id'),
        nombre: _texto(f, 'nombre'),
        nombreCorto: _textoONulo(f, 'nombre_corto'),
        ubicacion: _texto(f, 'ubicacion'),
        estado: EstadoObra.de(_texto(f, 'estado')),
        avancePct: _numero(f, 'avance_pct'),
        meta: _texto(f, 'meta'),
        montoAsignado: _numero(f, 'monto_asignado'),
        montoEjecutado: _numero(f, 'monto_ejecutado'),
        publicada: f['publicada'] == true,
        inicio: leerFecha(_textoONulo(f, 'inicio')),
        actualizadaEn: leerFecha(_textoONulo(f, 'actualizada_en')),
        porcentajeTributos: _numeroONulo(f, 'porcentaje_tributos'),
        hitos: f['hitos'] is List ? (f['hitos'] as List).map((h) => h.toString()).toList() : const [],
        latitud: _numeroONulo(f, 'latitud'),
        longitud: _numeroONulo(f, 'longitud'),
      );
}

/// Todo lo que la app muestra. Con Supabase, las políticas RLS ya dejan pasar
/// solo las filas del vecino.
class FuenteDatos {
  const FuenteDatos({
    this.municipalidades = const [],
    this.vecinos = const [],
    this.predios = const [],
    this.deudas = const [],
    this.pagos = const [],
    this.recordatorios = const [],
    this.reclamos = const [],
    this.obras = const [],
  });

  final List<Municipalidad> municipalidades;
  final List<Vecino> vecinos;
  final List<Predio> predios;
  final List<Deuda> deudas;
  final List<Pago> pagos;
  final List<Recordatorio> recordatorios;
  final List<Reclamo> reclamos;
  final List<Obra> obras;

  FuenteDatos con({List<Reclamo>? reclamos, List<Vecino>? vecinos}) => FuenteDatos(
        municipalidades: municipalidades,
        vecinos: vecinos ?? this.vecinos,
        predios: predios,
        deudas: deudas,
        pagos: pagos,
        recordatorios: recordatorios,
        reclamos: reclamos ?? this.reclamos,
        obras: obras,
      );
}

/// Lo que el vecino autoriza en Privacidad. Lo opcional empieza apagado:
/// requiere una acción afirmativa.
class Consentimientos {
  const Consentimientos({this.asistente = false, this.whatsapp = false, this.sms = false});

  final bool asistente;
  final bool whatsapp;
  final bool sms;

  Consentimientos con({bool? asistente, bool? whatsapp, bool? sms}) => Consentimientos(
        asistente: asistente ?? this.asistente,
        whatsapp: whatsapp ?? this.whatsapp,
        sms: sms ?? this.sms,
      );

  // Mismas claves que guarda la app anterior en `user_metadata.almira`.
  Map<String, dynamic> aJson() =>
      {'asistenteIa': asistente, 'avisosWhatsapp': whatsapp, 'avisosSms': sms};

  factory Consentimientos.deJson(Object? json) {
    if (json is! Map) return const Consentimientos();
    return Consentimientos(
      asistente: json['asistenteIa'] == true,
      whatsapp: json['avisosWhatsapp'] == true,
      sms: json['avisosSms'] == true,
    );
  }
}

/// Lo que se guarda al terminar el ingreso, para no pedirlo en cada apertura.
/// No lleva teléfono, DNI ni otros datos personales.
class DatosIngreso {
  const DatosIngreso({
    required this.municipalidadId,
    required this.consentimientos,
    required this.aceptadoEn,
  });

  final String municipalidadId;
  final Consentimientos consentimientos;
  final String aceptadoEn;

  DatosIngreso con({String? municipalidadId, Consentimientos? consentimientos}) => DatosIngreso(
        municipalidadId: municipalidadId ?? this.municipalidadId,
        consentimientos: consentimientos ?? this.consentimientos,
        aceptadoEn: aceptadoEn,
      );

  Map<String, dynamic> aJson() => {
        'municipalidadId': municipalidadId,
        'consentimientos': consentimientos.aJson(),
        'consentimientoAceptadoEn': aceptadoEn,
      };

  static DatosIngreso? deJson(Object? json) {
    if (json is! Map) return null;
    final municipalidad = json['municipalidadId'];
    final aceptado = json['consentimientoAceptadoEn'];
    if (municipalidad is! String || aceptado is! String) return null;
    return DatosIngreso(
      municipalidadId: municipalidad,
      consentimientos: Consentimientos.deJson(json['consentimientos']),
      aceptadoEn: aceptado,
    );
  }
}

/// Reclamo que el vecino está por enviar.
class NuevoReclamo {
  const NuevoReclamo({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.direccion,
    this.latitud,
    this.longitud,
    this.fotoRuta,
    this.fotoBytes,
  });

  final TipoReclamo tipo;
  final String titulo;
  final String descripcion;
  final String direccion;
  final double? latitud;
  final double? longitud;

  /// Archivo elegido en el teléfono.
  final String? fotoRuta;

  /// Contenido de la foto, ya reducida.
  final List<int>? fotoBytes;
}
