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

/// Ingreso a la app. Los métodos lanzan [ErrorApp] con un mensaje para mostrar.
abstract class ServicioAuth {
  bool get esDemo;
  Cuenta? get cuenta;
  Stream<Cuenta?> get cambios;

  Future<void> ingresarConCorreo(String correo, String clave);

  /// Devuelve false si la cuenta quedó creada pero falta confirmar el correo.
  Future<bool> crearCuenta(String correo, String clave);
  Future<void> ingresarConGoogle();
  Future<void> enviarCodigoSms(String celular);
  Future<void> verificarCodigoSms(String celular, String codigo);
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
  Future<bool> crearCuenta(String correo, String clave) async {
    final respuesta = await _intentar(
      () => _cliente.auth.signUp(email: correo.trim(), password: clave),
      'No pudimos crear la cuenta. Revisa el correo y usa al menos 8 caracteres.',
    );
    return respuesta.session != null;
  }

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
  Future<void> enviarCodigoSms(String celular) => _intentar(
        () => _cliente.auth.signInWithOtp(phone: '+51$celular'),
        'No pudimos enviar el código. Revisa tu número e inténtalo de nuevo.',
      );

  @override
  Future<void> verificarCodigoSms(String celular, String codigo) => _intentar(
        () => _cliente.auth.verifyOTP(phone: '+51$celular', token: codigo, type: OtpType.sms),
        'El código no es correcto o ya venció.',
      );

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
  Future<bool> crearCuenta(String correo, String clave) async => throw _noDisponible;

  @override
  Future<void> ingresarConGoogle() async => throw _noDisponible;

  @override
  Future<void> enviarCodigoSms(String celular) async => throw _noDisponible;

  @override
  Future<void> verificarCodigoSms(String celular, String codigo) async => throw _noDisponible;

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
