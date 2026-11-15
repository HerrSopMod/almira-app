import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/env.dart';
import 'features/assistant/servicio_asistente.dart';
import 'features/auth/servicio_auth.dart';
import 'shared/services/proveedores.dart';
import 'shared/services/repositorio.dart';
import 'shared/services/repositorio_demo.dart';
import 'shared/services/repositorio_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app dibuja detrás de las barras del sistema (Android 15 ya lo hace
  // siempre): cada pantalla pinta su franja superior y respeta el área segura.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(barraSobreTurquesa);

  final preferencias = await SharedPreferences.getInstance();
  final Repositorio repositorio;
  final ServicioAuth auth;
  ServicioAsistente? asistente;

  if (Env.supabaseConfigurado) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        // En el teléfono la sesión va cifrada; en la web, donde decide el navegador.
        localStorage: kIsWeb ? null : AlmacenSesionSegura(),
      ),
      debug: false,
    );
    final cliente = Supabase.instance.client;
    repositorio = RepositorioSupabase(cliente);
    auth = ServicioAuthSupabase(cliente);
    // Con conexión con el servicio, el asistente responde con la función de Supabase.
    asistente = ServicioAsistenteSupabase(cliente);
  } else {
    // Sin SUPABASE_URL ni SUPABASE_ANON_KEY: modo demostración, sin red.
    repositorio = RepositorioDemo(preferencias);
    auth = ServicioAuthDemo(preferencias);
  }

  runApp(
    ProviderScope(
      overrides: [
        preferenciasProvider.overrideWithValue(preferencias),
        repositorioProvider.overrideWithValue(repositorio),
        servicioAuthProvider.overrideWithValue(auth),
        if (asistente != null) servicioAsistenteProvider.overrideWithValue(asistente),
      ],
      child: const AlmiraApp(),
    ),
  );
}
