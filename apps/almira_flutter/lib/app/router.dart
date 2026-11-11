import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/asistente_screen.dart';
import '../features/account/cuponera_screen.dart';
import '../features/account/estado_cuenta_screen.dart';
import '../features/auth/configurar_screen.dart';
import '../features/auth/ingreso_screen.dart';
import '../features/auth/registro_screen.dart';
import '../features/auth/verificar_celular_screen.dart';
import '../features/complaints/nuevo_reclamo_screen.dart';
import '../features/complaints/reclamo_detalle_screen.dart';
import '../features/complaints/reclamos_screen.dart';
import '../features/home/inicio_screen.dart';
import '../features/notifications/avisos_screen.dart';
import '../features/onboarding/consentimiento_screen.dart';
import '../features/payments/deuda_detalle_screen.dart';
import '../features/payments/pago_confirmar_screen.dart';
import '../features/payments/pago_en_linea_screen.dart';
import '../features/payments/pagos_screen.dart';
import '../features/profile/atencion_screen.dart';
import '../features/profile/municipalidad_screen.dart';
import '../features/profile/perfil_screen.dart';
import '../features/profile/privacidad_screen.dart';
import '../features/profile/vincular_screen.dart';
import '../features/public_works/obra_detalle_screen.dart';
import '../features/public_works/obras_screen.dart';
import '../features/shell/shell_principal.dart';
import '../shared/services/proveedores.dart';

/// Rutas de la app.
abstract final class Rutas {
  static const ingreso = '/ingreso';
  static const registro = '/registro';
  static const configurar = '/configurar';
  static const verificarCelular = '/verificar-celular';
  static const consentimiento = '/consentimiento';
  static const inicio = '/inicio';
  static const pagos = '/pagos';
  static const pagoEnLinea = '/pagos/en-linea';
  static const confirmarPago = '/pagos/en-linea/confirmar';
  static const estadoCuenta = '/pagos/estado-cuenta';
  static const cuponera = '/pagos/cuponera';
  static const reclamos = '/reclamos';
  static const obras = '/obras';
  static const asistente = '/asistente';
  static const nuevoReclamo = '/reclamo-nuevo';
  static const perfil = '/perfil';
  static const avisos = '/perfil/avisos';
  static const privacidad = '/perfil/privacidad';
  static const municipalidad = '/perfil/municipalidad';
  static const vincular = '/perfil/vincular';
  static const atencion = '/perfil/atencion';

  static String deuda(String id) => '$pagos/deuda/$id';
  static String reclamo(String id) => '$reclamos/$id';
  static String obra(String id) => '$obras/$id';
}

const _pasosIngreso = [Rutas.configurar, Rutas.verificarCelular, Rutas.consentimiento];

/// Adónde va cada quien: sin cuenta, al ingreso; con cuenta a medio
/// configurar, a terminar el ingreso (una sola vez); con todo listo, directo
/// a Inicio. Así el recorrido inicial no reaparece en cada apertura.
String? redirigir(Sesion sesion, String ruta) {
  if (!sesion.conCuenta) {
    return ruta == Rutas.ingreso || ruta == Rutas.registro ? null : Rutas.ingreso;
  }
  if (!sesion.lista) {
    // Quien se registró con su cuponera ya eligió municipalidad: solo falta el consentimiento.
    final destino = sesion.municipalidadElegida != null ? Rutas.consentimiento : Rutas.configurar;
    return _pasosIngreso.contains(ruta) ? null : destino;
  }
  if (ruta == Rutas.ingreso || ruta == Rutas.registro || _pasosIngreso.contains(ruta)) {
    return Rutas.inicio;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final cambios = ValueNotifier<int>(0);
  ref.listen(sesionProvider, (_, _) => cambios.value++);
  ref.onDispose(cambios.dispose);

  return GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: cambios,
    redirect: (context, estado) => redirigir(ref.read(sesionProvider), estado.matchedLocation),
    // Un enlace desconocido (o el regreso de Google) cae en Inicio y de ahí
    // se redirige según la sesión.
    onException: (context, estado, router) => router.go(Rutas.inicio),
    routes: [
      GoRoute(path: Rutas.ingreso, builder: (_, _) => const IngresoScreen()),
      GoRoute(path: Rutas.registro, builder: (_, _) => const RegistroScreen()),
      GoRoute(path: Rutas.configurar, builder: (_, _) => const ConfigurarScreen()),
      GoRoute(path: Rutas.verificarCelular, builder: (_, _) => const VerificarCelularScreen()),
      GoRoute(path: Rutas.consentimiento, builder: (_, _) => const ConsentimientoScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navegacion) => ShellPrincipal(navegacion: navegacion),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Rutas.inicio, builder: (_, _) => const InicioScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.pagos,
              builder: (_, estado) =>
                  PagosScreen(filtroInicial: estado.uri.queryParameters['filtro']),
              routes: [
                GoRoute(
                  path: 'deuda/:id',
                  builder: (_, estado) => DeudaDetalleScreen(id: estado.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'en-linea',
                  builder: (_, _) => const PagoEnLineaScreen(),
                  routes: [
                    GoRoute(
                      path: 'confirmar',
                      builder: (_, estado) =>
                          PagoConfirmarScreen(deudaIds: (estado.extra as List<String>?) ?? const []),
                    ),
                  ],
                ),
                GoRoute(path: 'estado-cuenta', builder: (_, _) => const EstadoCuentaScreen()),
                GoRoute(path: 'cuponera', builder: (_, _) => const CuponeraScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.reclamos,
              builder: (_, _) => const ReclamosScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, estado) => ReclamoDetalleScreen(id: estado.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.obras,
              builder: (_, _) => const ObrasScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, estado) => ObraDetalleScreen(id: estado.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Rutas.asistente, builder: (_, _) => const AsistenteScreen()),
          ]),
        ],
      ),
      // Estas pantallas se abren encima de las pestañas.
      GoRoute(path: Rutas.nuevoReclamo, builder: (_, _) => const NuevoReclamoScreen()),
      GoRoute(
        path: Rutas.perfil,
        builder: (_, _) => const PerfilScreen(),
        routes: [
          GoRoute(path: 'avisos', builder: (_, _) => const AvisosScreen()),
          GoRoute(path: 'privacidad', builder: (_, _) => const PrivacidadScreen()),
          GoRoute(path: 'municipalidad', builder: (_, _) => const MunicipalidadScreen()),
          GoRoute(path: 'vincular', builder: (_, _) => const VincularScreen()),
          GoRoute(path: 'atencion', builder: (_, _) => const AtencionScreen()),
        ],
      ),
    ],
  );
});
