import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/error_app.dart';
import '../models/modelos.dart';
import '../models/preferencia_whatsapp.dart';
import 'repositorio.dart';

const _espera = Duration(seconds: 20);
const _bucket = 'evidencias';

/// Columnas de `vecinos` que el cliente puede leer. El número de cuponera (privado) no está:
/// la base ni siquiera deja pedirlo, así que nunca se usa `select *` en esa tabla.
const _columnasVecino =
    'id, municipalidad_id, user_id, dni, nombre, telefono, canal_preferido, codigo_contribuyente, '
    'nombres, apellidos, domicilio_fiscal';

/// Ante cualquier fallo de la vinculación se responde lo mismo: no se dice si falló la
/// cuponera, el DNI o la municipalidad.
const _mensajeVinculo = 'No pudimos verificar tus datos. Revisa la municipalidad, la cuponera y el DNI.';

/// Backend real: las tablas, políticas RLS y el bucket privado que ya existen
/// en `supabase/migrations`. No se cambia ningún contrato.
class RepositorioSupabase implements Repositorio {
  RepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  /// Fotos ya subidas en esta sesión, por archivo local: si el guardado del
  /// reclamo falla y el vecino reintenta, no se vuelve a subir la misma foto.
  final Map<String, String> _subidas = {};

  @override
  bool get esDemo => false;

  Future<List<T>> _leer<T>(
    String tabla,
    T Function(Fila fila) convertir, {
    String? orden,
    bool ascendente = true,
    String columnas = '*',
  }) async {
    final consulta = _cliente.from(tabla).select(columnas);
    final List<Fila> filas = orden == null
        ? await consulta
        : await consulta.order(orden, ascending: ascendente);
    return filas.map(convertir).toList();
  }

  @override
  Future<FuenteDatos> cargar() async {
    try {
      final r = await Future.wait<List<Object>>([
        _leer('municipalidades', Municipalidad.deFila, orden: 'nombre'),
        _leer('vecinos', Vecino.deFila, columnas: _columnasVecino),
        _leer('predios', Predio.deFila),
        _leer('deudas', Deuda.deFila, orden: 'vencimiento'),
        _leer('pagos', Pago.deFila, orden: 'creado_en', ascendente: false),
        _leer('recordatorios', Recordatorio.deFila),
        _leer('reclamos', Reclamo.deFila, orden: 'creado_en', ascendente: false),
        _leer('obras', Obra.deFila),
      ]).timeout(_espera);
      return FuenteDatos(
        municipalidades: r[0].cast<Municipalidad>(),
        vecinos: r[1].cast<Vecino>(),
        predios: r[2].cast<Predio>(),
        deudas: r[3].cast<Deuda>(),
        pagos: r[4].cast<Pago>(),
        recordatorios: r[5].cast<Recordatorio>(),
        reclamos: r[6].cast<Reclamo>(),
        obras: r[7].cast<Obra>(),
      );
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<String> crearReclamo(
    NuevoReclamo reclamo, {
    required String municipalidadId,
    required String vecinoId,
    void Function(EtapaEnvio etapa)? alAvanzar,
  }) async {
    final usuario = _cliente.auth.currentUser;
    final bytes = reclamo.fotoBytes;
    if (usuario == null) throw const ErrorApp(TipoError.sesionVencida);
    // La base exige la foto (`foto_ruta` es obligatoria).
    if (bytes == null || bytes.isEmpty) {
      throw const ErrorApp(TipoError.servidor, 'Adjunta una foto para enviar el reclamo.');
    }
    try {
      // La ruta {municipalidad}/{usuario}/{archivo} es la única carpeta donde
      // las políticas del bucket dejan subir.
      final clave = reclamo.fotoRuta ?? '';
      var ruta = _subidas[clave];
      if (ruta == null) {
        alAvanzar?.call(EtapaEnvio.subiendoFoto);
        // Una imagen PNG de la galería sigue siendo PNG tras reducirla.
        final esPng = bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E;
        ruta = '$municipalidadId/${usuario.id}/${DateTime.now().millisecondsSinceEpoch}'
            '.${esPng ? 'png' : 'jpg'}';
        await _cliente.storage
            .from(_bucket)
            .uploadBinary(
              ruta,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(contentType: esPng ? 'image/png' : 'image/jpeg'),
            )
            .timeout(const Duration(seconds: 60));
        if (clave.isNotEmpty) _subidas[clave] = ruta;
      }
      alAvanzar?.call(EtapaEnvio.guardando);
      // Solo las columnas que el vecino puede escribir (permisos por columna).
      final fila = await _cliente
          .from('reclamos')
          .insert({
            'municipalidad_id': municipalidadId,
            'vecino_id': vecinoId,
            'tipo': reclamo.tipo.clave,
            'titulo': reclamo.titulo,
            'descripcion': reclamo.descripcion,
            'foto_ruta': ruta,
            'direccion': reclamo.direccion,
            'latitud': reclamo.latitud,
            'longitud': reclamo.longitud,
          })
          .select('id')
          .single()
          .timeout(_espera);
      _subidas.remove(clave);
      return fila['id'].toString();
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<FotoReclamo?> fotoDe(Reclamo reclamo) async {
    if (!reclamo.tieneFoto) return null;
    try {
      // Bucket privado: el vecino solo puede firmar las rutas de su carpeta.
      final url = await _cliente.storage
          .from(_bucket)
          .createSignedUrl(reclamo.fotoRuta!, 3600)
          .timeout(_espera);
      return FotoReclamo.url(url);
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<void> cambiarCanal(String vecinoId, CanalAviso canal) async {
    try {
      await _cliente
          .from('vecinos')
          .update({'canal_preferido': canal.name})
          .eq('id', vecinoId)
          .timeout(_espera);
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<bool> guardarCelular(String celular) async {
    try {
      final r = await _cliente.rpc('guardar_celular', params: {'p_celular': celular}).timeout(_espera);
      return r == true;
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<PreferenciaWhatsapp?> preferenciaWhatsapp() async {
    try {
      // La política RLS deja ver solo la fila propia.
      final filas = await _cliente
          .from('preferencias_notificacion')
          .select('whatsapp_activo, whatsapp_numero')
          .limit(1)
          .timeout(_espera);
      if (filas.isEmpty) return null;
      final fila = filas.first;
      return PreferenciaWhatsapp(
        activo: fila['whatsapp_activo'] == true,
        numero: fila['whatsapp_numero'] as String?,
      );
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<ResultadoWhatsapp> activarWhatsapp(String celular) async {
    try {
      final guardado = await _cliente.rpc('activar_whatsapp', params: {
        'p_numero': celular,
        'p_version': versionConsentimientoWhatsapp,
      }).timeout(_espera);
      if (guardado == 'sin_vinculo') return ResultadoWhatsapp.sinVinculo;
      if (guardado != 'ok') return ResultadoWhatsapp.noSeEnvio;
    } catch (error) {
      throw ErrorApp.de(error);
    }

    // Preferencia guardada: ahora la función manda la bienvenida al número ya guardado.
    ResultadoWhatsapp resultado;
    try {
      final respuesta = await _cliente.functions
          .invoke('enviar-recordatorios', body: {'accion': 'bienvenida'}).timeout(const Duration(seconds: 30));
      final datos = respuesta.data;
      if (datos is Map && datos['enviado'] == true) return ResultadoWhatsapp.activado;
      resultado = datos is Map && datos['motivo'] == 'limite' ? ResultadoWhatsapp.limite : ResultadoWhatsapp.noSeEnvio;
    } on FunctionException catch (error) {
      resultado = error.status == 429 ? ResultadoWhatsapp.limite : ResultadoWhatsapp.noSeEnvio;
    } catch (error) {
      await _apagarSinFallar();
      throw ErrorApp.de(error);
    }
    // El mensaje no llegó: no se deja activo un número al que no se pudo escribir.
    await _apagarSinFallar();
    return resultado;
  }

  Future<void> _apagarSinFallar() async {
    try {
      await _cliente.rpc('desactivar_whatsapp').timeout(_espera);
    } catch (_) {
      // Si tampoco hay conexión para apagarlo, se corrige al reintentar.
    }
  }

  @override
  Future<void> desactivarWhatsapp() async {
    try {
      await _cliente.rpc('desactivar_whatsapp').timeout(_espera);
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Future<String> pagar(List<String> deudaIds, MedioPago medio) async {
    try {
      final operacion = await _cliente.rpc('registrar_pago', params: {
        'p_deudas': deudaIds,
        'p_medio': medio.clave,
      }).timeout(_espera);
      return operacion.toString();
    } on PostgrestException catch (error) {
      final m = error.message;
      throw ErrorApp(
        TipoError.servidor,
        m.contains('deudas_invalidas')
            ? 'Alguna de las deudas ya fue pagada. Actualiza la pantalla e inténtalo de nuevo.'
            : 'No pudimos registrar el pago. Inténtalo de nuevo.',
      );
    } catch (error) {
      throw ErrorApp.de(error);
    }
  }

  @override
  Stream<void> get cambiosDeudas {
    late final StreamController<void> control;
    RealtimeChannel? canal;
    control = StreamController<void>.broadcast(
      onListen: () {
        canal = _cliente
            .channel('deudas-vecino')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'deudas',
              callback: (_) => control.add(null),
            )
            .subscribe();
      },
      onCancel: () async {
        final abierto = canal;
        if (abierto != null) await _cliente.removeChannel(abierto);
      },
    );
    return control.stream;
  }

  @override
  Future<String?> vincularCodigo(String municipalidadId, String codigo, String dni) async {
    try {
      final resultado = await _cliente.rpc('vincular_contribuyente', params: {
        'p_municipalidad': municipalidadId,
        'p_codigo': codigo.trim(),
        'p_dni': dni.trim(),
      }).timeout(_espera);
      return resultado == true ? null : _mensajeVinculo;
    } on PostgrestException catch (error) {
      if (error.message.contains('demasiados_intentos')) {
        return 'Hiciste demasiados intentos. Espera 15 minutos e inténtalo de nuevo.';
      }
      return _mensajeVinculo;
    } catch (error) {
      final e = ErrorApp.de(error);
      return e.sinConexion
          ? 'Sin conexión. Revisa tu internet e inténtalo de nuevo.'
          : _mensajeVinculo;
    }
  }
}
