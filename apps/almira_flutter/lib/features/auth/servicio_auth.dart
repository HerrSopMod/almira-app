import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/errors/error_app.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/datos_demo.dart';

/// La cuenta que ingresó. No guarda DNI ni teléfono.
class Cuenta {
  const Cuenta({required this.id, this.nombre, this.ingreso});

  final String id;

  /// Nombre que trae la cuenta (por ejemplo, la de Google), si lo hay.
  final String? nombre;

  /// Lo que eligió al terminar el ingreso, o null si todavía no lo terminó.
  final DatosIngreso? ingreso;
}

/// Municipalidad que se puede elegir al registrarse.
class MunicipalidadRegistro {
  const MunicipalidadRegistro({required this.id, required this.slug, required this.nombre, this.zona = ''});

  final String id;
  final String slug;
  final String nombre;
  final String zona;

  factory MunicipalidadRegistro.deJson(Map<String, dynamic> f) => MunicipalidadRegistro(
        id: '${f['id']}',
        slug: '${f['slug']}',
        nombre: '${f['nombre']}',
        zona: '${f['zona'] ?? ''}',
      );
}

/// Ingreso a la app. Los métodos lanzan [ErrorApp] con un mensaje para mostrar.
abstract class ServicioAuth {
  bool get esDemo;
  Cuenta? get cuenta;
  Stream<Cuenta?> get cambios;

  /// Ingreso con Google (Supabase Auth). Abre el navegador y vuelve a la app por `almira://ingreso`.
  Future<void> ingresarConGoogle();

  Future<void> ingresarConCorreo(String correo, String clave);

  /// Crea (o cambia) la clave web de la cuenta, para entrar después con correo o cuponera.
  Future<void> crearClaveWeb(String clave);

  /// Ingreso con el código de contribuyente (el del estado de cuenta) y la clave web.
  Future<void> ingresarConCodigo(String codigo, String clave);

  /// Municipalidades entre las que se elige al registrarse.
  Future<List<MunicipalidadRegistro>> municipalidadesRegistro();

  /// Comprueba en el servidor que el número de cuponera y el DNI son de esa municipalidad y que nadie
  /// los vinculó todavía. Si no, lanza un error genérico: no dice cuál dato falló.
  Future<void> verificarCuponera({required String slug, required String cuponera, required String dni});

  /// Crea la cuenta con correo y clave, la vincula con el contribuyente e inicia sesión.
  Future<void> registrarConCuponera({
    required String slug,
    required String cuponera,
    required String dni,
    required String correo,
    required String clave,
    required String celular,
  });

  Future<void> ingresarDemo();
  Future<void> guardarIngreso(DatosIngreso datos);
  Future<void> cerrarSesion();
}

/// La sesión de Supabase se guarda cifrada (Keystore de Android / Keychain),
/// no en texto plano.
class AlmacenSesionSegura extends LocalStorage {
  const AlmacenSesionSegura();

  static const _almacen = FlutterSecureStorage();
  static const _clave = 'almira.sesion';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _almacen.read(key: _clave);

  @override
  Future<bool> hasAccessToken() => _almacen.containsKey(key: _clave);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _almacen.write(key: _clave, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _almacen.delete(key: _clave);
}

/// Supabase Auth, con el mismo contrato que la app anterior: Google, correo y
/// celular (+51), y lo elegido en el ingreso dentro de `user_metadata.almira`.
class ServicioAuthSupabase implements ServicioAuth {
  ServicioAuthSupabase(this._cliente);

  final SupabaseClient _cliente;
  static const _claveDatos = 'almira';

  @override
  bool get esDemo => false;

  Cuenta? _de(User? usuario) {
    if (usuario == null) return null;
    final meta = usuario.userMetadata ?? const {};
    final nombre = meta['full_name'] ?? meta['name'];
    return Cuenta(
      id: usuario.id,
      nombre: nombre is String && nombre.trim().isNotEmpty ? nombre.trim() : null,
      ingreso: DatosIngreso.deJson(meta[_claveDatos]),
    );
  }

  @override
  Cuenta? get cuenta => _de(_cliente.auth.currentUser);

  @override
  Stream<Cuenta?> get cambios =>
      _cliente.auth.onAuthStateChange.map((estado) => _de(estado.session?.user));

  Future<T> _intentar<T>(Future<T> Function() accion, String mensaje) async {
    try {
      return await accion().timeout(const Duration(seconds: 25));
    } on AuthException {
      throw ErrorApp(TipoError.servidor, mensaje);
    } catch (error) {
      final e = ErrorApp.de(error);
      throw e.sinConexion
          ? const ErrorApp(TipoError.sinConexion, 'Sin conexión. Revisa tu internet e inténtalo de nuevo.')
          : ErrorApp(TipoError.servidor, mensaje);
    }
  }

  @override
  Future<void> ingresarConCorreo(String correo, String clave) => _intentar(
        () => _cliente.auth.signInWithPassword(email: correo.trim(), password: clave),
        'Correo o contraseña incorrectos.',
      );

  @override
  Future<void> ingresarConGoogle() => _intentar(
        () => _cliente.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : Env.retornoIngreso,
          authScreenLaunchMode: LaunchMode.externalApplication,
        ),
        'No pudimos abrir el ingreso con Google. Inténtalo de nuevo.',
      );

  @override
  Future<void> crearClaveWeb(String clave) => _intentar(
        () => _cliente.auth.updateUser(UserAttributes(password: clave)),
        'No pudimos guardar tu clave. Usa al menos 8 caracteres e inténtalo de nuevo.',
      );

  /// Llama a la función del servidor. Ante un rechazo muestra el mensaje que ella devuelve.
  Future<Map<String, dynamic>> _llamar(Map<String, dynamic> cuerpo) async {
    try {
      final respuesta = await _cliente.functions
          .invoke('registro-contribuyente', body: cuerpo)
          .timeout(const Duration(seconds: 25));
      final datos = respuesta.data;
      return datos is Map ? Map<String, dynamic>.from(datos) : <String, dynamic>{};
    } on FunctionException catch (error) {
      final detalles = error.details;
      final mensaje = detalles is Map ? detalles['error'] : null;
      throw ErrorApp(
        TipoError.servidor,
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No pudimos verificar tus datos. Revisa la municipalidad, la cuponera y el DNI.',
      );
    } catch (error) {
      final e = ErrorApp.de(error);
      throw e.sinConexion
          ? const ErrorApp(TipoError.sinConexion, 'Sin conexión. Revisa tu internet e inténtalo de nuevo.')
          : const ErrorApp(TipoError.servidor, 'No pudimos completar la solicitud. Inténtalo de nuevo.');
    }
  }

  @override
  Future<void> ingresarConCodigo(String codigo, String clave) async {
    final r = await _llamar({'accion': 'ingresar', 'codigo': codigo.trim(), 'clave': clave});
    final refresco = r['refresh_token'];
    if (refresco is! String) {
      throw const ErrorApp(TipoError.servidor, 'Código o clave incorrectos.');
    }
    await _intentar(
      () => _cliente.auth.setSession(refresco),
      'No pudimos iniciar tu sesión. Inténtalo de nuevo.',
    );
  }

  @override
  Future<List<MunicipalidadRegistro>> municipalidadesRegistro() async {
    final r = await _llamar({'accion': 'municipalidades'});
    final lista = r['municipalidades'];
    if (lista is! List) return const [];
    return lista
        .map((f) => MunicipalidadRegistro.deJson(Map<String, dynamic>.from(f as Map)))
        .toList();
  }

  @override
  Future<void> verificarCuponera({
    required String slug,
    required String cuponera,
    required String dni,
  }) async {
    await _llamar({'accion': 'verificar', 'slug': slug, 'cuponera': cuponera.trim(), 'dni': dni.trim()});
  }

  @override
  Future<void> registrarConCuponera({
    required String slug,
    required String cuponera,
    required String dni,
    required String correo,
    required String clave,
    required String celular,
  }) async {
    await _llamar({
      'accion': 'registrar',
      'slug': slug,
      'cuponera': cuponera.trim(),
      'dni': dni.trim(),
      'correo': correo.trim(),
      'clave': clave,
      'celular': celular,
    });
    await ingresarConCorreo(correo, clave);
  }

  @override
  Future<void> ingresarDemo() async {}

  @override
  Future<void> guardarIngreso(DatosIngreso datos) => _intentar(
        () => _cliente.auth.updateUser(UserAttributes(data: {_claveDatos: datos.aJson()})),
        'No pudimos guardar tus preferencias. Inténtalo de nuevo.',
      );

  @override
  Future<void> cerrarSesion() async {
    try {
      await _cliente.auth.signOut();
    } catch (_) {
      // Sin conexión, la sesión local igual se cierra.
      await _cliente.auth.signOut(scope: SignOutScope.local);
    }
  }
}

/// Modo demostración: no hay cuentas ni contraseñas. Solo recuerda en el
/// teléfono si ya se entró y qué se eligió.
class ServicioAuthDemo implements ServicioAuth {
  ServicioAuthDemo(this._preferencias);

  final SharedPreferences _preferencias;
  final _control = StreamController<Cuenta?>.broadcast();
  static const _claveSesion = 'demo.sesion';
  static const _claveIngreso = 'demo.ingreso';

  @override
  bool get esDemo => true;

  @override
  Cuenta? get cuenta {
    if (_preferencias.getBool(_claveSesion) != true) return null;
    final texto = _preferencias.getString(_claveIngreso);
    DatosIngreso? ingreso;
    if (texto != null) {
      try {
        ingreso = DatosIngreso.deJson(jsonDecode(texto));
      } catch (_) {
        ingreso = null;
      }
    }
    return Cuenta(id: DatosDemo.usuarioId, ingreso: ingreso);
  }

  @override
  Stream<Cuenta?> get cambios => _control.stream;

  ErrorApp get _noDisponible => const ErrorApp(
        TipoError.servidor,
        'El ingreso con cuenta necesita conexión con el servicio. Usa la demostración.',
      );

  @override
  Future<void> ingresarConCorreo(String correo, String clave) async => throw _noDisponible;

  @override
  Future<void> ingresarConGoogle() async => throw _noDisponible;

  @override
  Future<void> crearClaveWeb(String clave) async => throw _noDisponible;

  @override
  Future<void> ingresarConCodigo(String codigo, String clave) async => throw _noDisponible;

  @override
  Future<List<MunicipalidadRegistro>> municipalidadesRegistro() async => throw _noDisponible;

  @override
  Future<void> verificarCuponera({
    required String slug,
    required String cuponera,
    required String dni,
  }) async =>
      throw _noDisponible;

  @override
  Future<void> registrarConCuponera({
    required String slug,
    required String cuponera,
    required String dni,
    required String correo,
    required String clave,
    required String celular,
  }) async =>
      throw _noDisponible;

  @override
  Future<void> ingresarDemo() async {
    await _preferencias.setBool(_claveSesion, true);
    _control.add(cuenta);
  }

  @override
  Future<void> guardarIngreso(DatosIngreso datos) async {
    await _preferencias.setString(_claveIngreso, jsonEncode(datos.aJson()));
    _control.add(cuenta);
  }

  @override
  Future<void> cerrarSesion() async {
    await _preferencias.remove(_claveSesion);
    await _preferencias.remove(_claveIngreso);
    _control.add(null);
  }
}
