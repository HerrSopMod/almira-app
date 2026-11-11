/// Configuración que entra al compilar con `--dart-define-from-file=env.json`.
/// Nunca va en el código: `env.json` está fuera de git (ver `env.example.json`).
/// Solo se usa la clave anon (pública); la `service_role` jamás entra a la app.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Sin estas dos variables, la app abre en modo demostración.
  static bool get supabaseConfigurado =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  /// Adonde vuelve el ingreso con Google. Debe estar en la lista de
  /// "Redirect URLs" del proyecto de Supabase.
  static const retornoIngreso = 'almira://ingreso';
}
