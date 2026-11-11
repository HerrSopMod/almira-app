import 'dart:async';
import 'dart:io';

/// Qué pasó, en términos que la interfaz sabe explicar.
enum TipoError { sinConexion, servidor, sesionVencida }

/// Error ya traducido para mostrar al vecino. Nunca lleva el error crudo.
class ErrorApp implements Exception {
  const ErrorApp(this.tipo, [this.mensaje]);

  final TipoError tipo;
  final String? mensaje;

  bool get sinConexion => tipo == TipoError.sinConexion;

  /// Clasifica cualquier excepción: distingue la falta de internet de un fallo
  /// del servicio para que la pantalla no muestre "sin datos" por error.
  factory ErrorApp.de(Object error) {
    if (error is ErrorApp) return error;
    final texto = error.toString();
    final red = error is SocketException ||
        error is TimeoutException ||
        texto.contains('SocketException') ||
        texto.contains('Failed host lookup') ||
        texto.contains('ClientException') ||
        texto.contains('Connection') ||
        texto.contains('XMLHttpRequest');
    if (red) return const ErrorApp(TipoError.sinConexion);
    if (texto.contains('JWT') || texto.contains('401')) {
      return const ErrorApp(TipoError.sesionVencida);
    }
    return const ErrorApp(TipoError.servidor);
  }

  String get titulo => switch (tipo) {
        TipoError.sinConexion => 'Sin conexión',
        TipoError.servidor => 'No pudimos cargar la información',
        TipoError.sesionVencida => 'Tu sesión venció',
      };

  String get detalle =>
      mensaje ??
      switch (tipo) {
        TipoError.sinConexion => 'Revisa tu internet e inténtalo de nuevo.',
        TipoError.servidor => 'Inténtalo de nuevo en un momento.',
        TipoError.sesionVencida => 'Vuelve a ingresar para continuar.',
      };

  @override
  String toString() => 'ErrorApp(${tipo.name})';
}
