import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/error_app.dart';
import '../../features/auth/servicio_auth.dart';
import '../models/modelos.dart';
import 'repositorio.dart';

// Los tres se reemplazan en `main.dart` (y en las pruebas) con `overrides`.
final preferenciasProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
final repositorioProvider = Provider<Repositorio>((ref) => throw UnimplementedError());
final servicioAuthProvider = Provider<ServicioAuth>((ref) => throw UnimplementedError());

/// "Hoy". Las pruebas lo fijan; la app usa siempre la fecha real del teléfono.
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final esDemoProvider = Provider<bool>((ref) => ref.watch(repositorioProvider).esDemo);

/// Estado del ingreso.
class Sesion {
  const Sesion({this.cuenta, this.municipalidadElegida});

  final Cuenta? cuenta;

  /// Municipalidad elegida durante el ingreso, antes de guardar.
  final String? municipalidadElegida;

  bool get conCuenta => cuenta != null;

  /// true cuando ya terminó el ingreso: recién ahí entra a Inicio.
  bool get lista => cuenta?.ingreso != null;
  String? get usuarioId => cuenta?.id;
  String? get municipalidadId => cuenta?.ingreso?.municipalidadId ?? municipalidadElegida;
  Consentimientos get consentimientos =>
      cuenta?.ingreso?.consentimientos ?? const Consentimientos();
}

class SesionNotifier extends Notifier<Sesion> {
  ServicioAuth get _auth => ref.read(servicioAuthProvider);

  @override
  Sesion build() {
    final auth = ref.watch(servicioAuthProvider);
    final suscripcion = auth.cambios.listen((cuenta) {
      // Si entra otra cuenta, no hereda lo elegido por la anterior.
      // La municipalidad elegida antes de ingresar (registro) se conserva al entrar la cuenta.
      final mismaCuenta = cuenta?.id == state.cuenta?.id || state.cuenta == null;
      state = Sesion(
        cuenta: cuenta,
        municipalidadElegida: mismaCuenta ? state.municipalidadElegida : null,
      );
    });
    ref.onDispose(suscripcion.cancel);
    return Sesion(cuenta: auth.cuenta);
  }

  void elegirMunicipalidad(String id) =>
      state = Sesion(cuenta: state.cuenta, municipalidadElegida: id);

  Future<void> _guardar(DatosIngreso datos) async {
    await _auth.guardarIngreso(datos);
    final cuenta = state.cuenta;
    if (cuenta == null) return;
    state = Sesion(
      cuenta: Cuenta(id: cuenta.id, nombre: cuenta.nombre, ingreso: datos),
      municipalidadElegida: state.municipalidadElegida,
    );
  }

  /// Cierra el ingreso: guarda la municipalidad y las preferencias elegidas.
  Future<void> completarIngreso(Consentimientos consentimientos) {
    final municipalidad = state.municipalidadId;
    if (municipalidad == null) {
      throw const ErrorApp(TipoError.servidor, 'Elige tu municipalidad para continuar.');
    }
    return _guardar(DatosIngreso(
      municipalidadId: municipalidad,
      consentimientos: consentimientos,
      aceptadoEn: ref.read(relojProvider)().toUtc().toIso8601String(),
    ));
  }

  Future<void> guardarConsentimientos(Consentimientos consentimientos) async {
    final ingreso = state.cuenta?.ingreso;
    if (ingreso != null) await _guardar(ingreso.con(consentimientos: consentimientos));
  }

  Future<void> cambiarMunicipalidad(String id) async {
    final ingreso = state.cuenta?.ingreso;
    if (ingreso != null) await _guardar(ingreso.con(municipalidadId: id));
  }

  Future<void> cerrarSesion() async {
    await _auth.cerrarSesion();
    state = const Sesion();
  }
}

final sesionProvider = NotifierProvider<SesionNotifier, Sesion>(SesionNotifier.new);

/// Datos del vecino. Se vuelven a leer cuando cambia la cuenta.
class DatosNotifier extends AsyncNotifier<FuenteDatos> {
  @override
  Future<FuenteDatos> build() async {
    final usuario = ref.watch(sesionProvider.select((s) => s.usuarioId));
    if (usuario == null) return const FuenteDatos();
    final repositorio = ref.watch(repositorioProvider);
    // Cuando cambia una deuda (por ejemplo, tras un pago) la pantalla se actualiza sola.
    Timer? espera;
    final suscripcion = repositorio.cambiosDeudas.listen((_) {
      espera?.cancel();
      espera = Timer(const Duration(milliseconds: 400), recargar);
    });
    ref.onDispose(() {
      espera?.cancel();
      suscripcion.cancel();
    });
    return repositorio.cargar();
  }

  /// Vuelve a leer sin borrar lo que ya se ve.
  Future<void> recargar() async {
    state = const AsyncLoading<FuenteDatos>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => ref.read(repositorioProvider).cargar());
  }
}

final datosProvider = AsyncNotifierProvider<DatosNotifier, FuenteDatos>(DatosNotifier.new);

/// Lo que el vecino ve: solo lo de la municipalidad elegida.
class VistaMunicipal {
  const VistaMunicipal({
    required this.municipalidad,
    required this.vecino,
    required this.predios,
    required this.deudas,
    required this.pagos,
    required this.recordatorios,
    required this.reclamos,
    required this.obras,
    required this.municipalidades,
  });

  /// Null mientras no haya municipalidades que mostrar.
  final Municipalidad? municipalidad;

  /// Null si la cuenta todavía no vinculó un código en esta municipalidad.
  final Vecino? vecino;
  final List<Predio> predios;
  final List<Deuda> deudas;
  final List<Pago> pagos;
  final List<Recordatorio> recordatorios;
  final List<Reclamo> reclamos;
  final List<Obra> obras;
  final List<Municipalidad> municipalidades;

  List<Deuda> get pendientes => deudas.where((d) => d.pendiente).toList();
}

VistaMunicipal crearVista(FuenteDatos datos, {String? municipalidadId, String? usuarioId}) {
  final activas = datos.municipalidades.where((m) => m.activa).toList();
  final municipalidad = activas.where((m) => m.id == municipalidadId).firstOrNull ??
      activas.firstOrNull;
  final vecino = datos.vecinos
      .where((v) => v.municipalidadId == municipalidad?.id && v.userId == usuarioId)
      .firstOrNull;
  bool propio(String vecinoId) => vecino != null && vecinoId == vecino.id;
  return VistaMunicipal(
    municipalidad: municipalidad,
    vecino: vecino,
    predios: datos.predios.where((p) => propio(p.vecinoId)).toList(),
    deudas: datos.deudas.where((d) => propio(d.vecinoId)).toList(),
    pagos: datos.pagos.where((p) => propio(p.vecinoId)).toList(),
    recordatorios: datos.recordatorios.where((r) => propio(r.vecinoId)).toList(),
    reclamos: datos.reclamos.where((r) => propio(r.vecinoId)).toList(),
    obras: datos.obras
        .where((o) => o.municipalidadId == municipalidad?.id && o.publicada)
        .toList(),
    municipalidades: activas,
  );
}

final vistaProvider = Provider<AsyncValue<VistaMunicipal>>((ref) {
  final sesion = ref.watch(sesionProvider);
  return ref.watch(datosProvider).whenData(
        (datos) => crearVista(
          datos,
          municipalidadId: sesion.municipalidadId,
          usuarioId: sesion.usuarioId,
        ),
      );
});

/// "Texto más grande": se recuerda en el teléfono.
class TextoGrandeNotifier extends Notifier<bool> {
  static const _clave = 'preferencias.textoGrande';

  @override
  bool build() => ref.watch(preferenciasProvider).getBool(_clave) ?? false;

  Future<void> cambiar(bool activo) async {
    state = activo;
    await ref.read(preferenciasProvider).setBool(_clave, activo);
  }
}

final textoGrandeProvider = NotifierProvider<TextoGrandeNotifier, bool>(TextoGrandeNotifier.new);
