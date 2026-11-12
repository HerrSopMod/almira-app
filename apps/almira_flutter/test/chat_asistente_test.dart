import 'dart:async';

import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/features/assistant/chat_asistente.dart';
import 'package:almira_flutter/features/assistant/chat_modelo.dart';
import 'package:almira_flutter/features/assistant/servicio_asistente.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10, 30);

/// Asistente de mentira: responde lo que se le diga y anota lo que recibe.
class _Falso implements ServicioAsistente {
  _Falso(this.responder);

  final Future<RespuestaAsistente> Function(String mensaje, List<MensajeChat> historial) responder;
  final preguntas = <String>[];
  final historiales = <List<MensajeChat>>[];

  @override
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial) {
    preguntas.add(mensaje);
    historiales.add(historial);
    return responder(mensaje, historial);
  }
}

ProviderContainer _contenedor(_Falso servicio) {
  final c = ProviderContainer(overrides: [
    servicioAsistenteProvider.overrideWithValue(servicio),
    relojProvider.overrideWithValue(() => _hoy),
    sesionProvider.overrideWith(() => _SesionDePrueba()),
  ]);
  addTearDown(c.dispose);
  return c;
}

class _SesionDePrueba extends SesionNotifier {
  @override
  Sesion build() => const Sesion(cuenta: Cuenta(id: 'u1'));
}

MensajeChat _m(String texto, bool mio) => MensajeChat(texto: texto, mio: mio, hora: _hoy);

void main() {
  group('agrupación de mensajes', () {
    test('el primero y el último de cada grupo seguido del mismo autor', () {
      final g = agruparMensajes([_m('a', false), _m('b', false), _m('c', true), _m('d', false)]);
      expect(g.map((p) => p.primero), [true, false, true, true]);
      expect(g.map((p) => p.ultimo), [false, true, true, true]);
    });

    test('un solo mensaje es primero y último a la vez', () {
      final g = agruparMensajes([_m('a', true)]);
      expect(g.single.primero && g.single.ultimo, isTrue);
      expect(agruparMensajes(const []), isEmpty);
    });
  });

  group('acciones del servidor', () {
    test('solo se aceptan las cuatro conocidas', () {
      expect(AccionChat.deServidor('pagar')!.ruta, Rutas.pagoEnLinea);
      expect(AccionChat.deServidor('ver_estado_cuenta')!.ruta, Rutas.estadoCuenta);
      expect(AccionChat.deServidor('ver_historial')!.ruta, Rutas.estadoCuenta);
      expect(AccionChat.deServidor('descargar_cuponera')!.ruta, Rutas.cuponera);
      expect(AccionChat.deServidor('borrar_todo'), isNull);
      expect(AccionChat.deServidor(null), isNull);
    });
  });

  group('conversación', () {
    test('envía, espera y agrega la respuesta con sus acciones', () async {
      final servicio = _Falso((_, _) async => const RespuestaAsistente(
            'Debes S/ 41.35.',
            acciones: [AccionChat('Pagar en línea', Rutas.pagoEnLinea)],
          ));
      final c = _contenedor(servicio);
      final enviado = c.read(chatAsistenteProvider.notifier).enviar('  ¿Cuánto debo?  ');
      expect(c.read(chatAsistenteProvider).enviando, isTrue);
      await enviado;
      final estado = c.read(chatAsistenteProvider);
      expect(estado.enviando, isFalse);
      expect(estado.mensajes.map((m) => m.texto), ['¿Cuánto debo?', 'Debes S/ 41.35.']);
      expect(estado.mensajes.map((m) => m.mio), [true, false]);
      expect(estado.mensajes.last.acciones.single.ruta, Rutas.pagoEnLinea);
      expect(servicio.preguntas, ['¿Cuánto debo?']);
    });

    test('un mensaje vacío o mientras se espera no se envía', () async {
      final espera = Completer<RespuestaAsistente>();
      final servicio = _Falso((_, _) => espera.future);
      final c = _contenedor(servicio);
      await c.read(chatAsistenteProvider.notifier).enviar('   ');
      expect(servicio.preguntas, isEmpty);
      final primero = c.read(chatAsistenteProvider.notifier).enviar('hola');
      await c.read(chatAsistenteProvider.notifier).enviar('otro mensaje');
      expect(servicio.preguntas, ['hola']);
      espera.complete(const RespuestaAsistente('Hola'));
      await primero;
    });

    test('el historial que recibe el servicio es lo anterior a la pregunta', () async {
      final servicio = _Falso((_, _) async => const RespuestaAsistente('ok'));
      final c = _contenedor(servicio);
      await c.read(chatAsistenteProvider.notifier).enviar('uno');
      await c.read(chatAsistenteProvider.notifier).enviar('dos');
      expect(servicio.historiales[0], isEmpty);
      expect(servicio.historiales[1].map((m) => m.texto), ['uno', 'ok']);
    });

    test('si falla, la burbuja ofrece reintentar y el reintento no repite el mensaje del vecino', () async {
      var intento = 0;
      final servicio = _Falso((_, _) async {
        intento++;
        return intento == 1
            ? const RespuestaAsistente('No pude responder.', fallo: true)
            : const RespuestaAsistente('Ahora sí: S/ 41.35.');
      });
      final c = _contenedor(servicio);
      await c.read(chatAsistenteProvider.notifier).enviar('¿Cuánto debo?');
      expect(c.read(chatAsistenteProvider).mensajes.last.fallo, isTrue);
      await c.read(chatAsistenteProvider.notifier).reintentar();
      final textos = c.read(chatAsistenteProvider).mensajes.map((m) => m.texto).toList();
      expect(textos, ['¿Cuánto debo?', 'Ahora sí: S/ 41.35.']);
      expect(servicio.preguntas, ['¿Cuánto debo?', '¿Cuánto debo?']);
    });

    test('una excepción del servicio se vuelve un mensaje amable con reintento', () async {
      final servicio = _Falso((_, _) async => throw Exception('red caída'));
      final c = _contenedor(servicio);
      await c.read(chatAsistenteProvider.notifier).enviar('hola');
      final ultimo = c.read(chatAsistenteProvider).mensajes.last;
      expect(ultimo.fallo, isTrue);
      expect(ultimo.texto, isNot(contains('red caída')));
    });
  });

  group('pantalla', () {
    Widget app(SharedPreferences p, ServicioAsistente servicio) => ProviderScope(
          overrides: [
            preferenciasProvider.overrideWithValue(p),
            repositorioProvider.overrideWithValue(RepositorioDemo(p, reloj: () => _hoy)),
            servicioAuthProvider.overrideWithValue(ServicioAuthDemo(p)),
            relojProvider.overrideWithValue(() => _hoy),
            servicioAsistenteProvider.overrideWithValue(servicio),
          ],
          child: const AlmiraApp(),
        );

    testWidgets('muestra el saludo, las sugerencias, la respuesta, los botones y se puede reintentar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'demo.sesion': true, 'demo.ingreso': _ingresoJson});
      final preferencias = await SharedPreferences.getInstance();
      var llamadas = 0;
      final servicio = _Falso((_, _) async {
        llamadas++;
        return llamadas == 1
            ? const RespuestaAsistente('No pude responder.', fallo: true)
            : const RespuestaAsistente(
                'Tu total pendiente es S/ 120.50.',
                acciones: [AccionChat('Pagar en línea', Rutas.pagoEnLinea)],
              );
      });
      await tester.pumpWidget(app(preferencias, servicio));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider).go(Rutas.asistente);
      await tester.pumpAndSettle();

      expect(find.text('Asistente Almira'), findsOneWidget);
      expect(find.text('En línea'), findsOneWidget);
      expect(find.textContaining('Soy Almira'), findsOneWidget);
      for (final s in ['¿Cuánto debo?', 'Mi último pago', '¿Cómo pago?', 'Mi estado de cuenta']) {
        expect(find.text(s), findsOneWidget);
      }

      // El botón de enviar está apagado sin texto.
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded)).onPressed, isNull);

      await tester.tap(find.text('¿Cuánto debo?'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      // Con una conversación en curso, las sugerencias se van.
      expect(find.text('Mi último pago'), findsNothing);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Tu total pendiente es S/ 120.50.'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('Pagar en línea'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

const _ingresoJson =
    '{"municipalidadId":"demo-lince","consentimientos":{"asistente":false,"whatsapp":false,"sms":false},'
    '"consentimientoAceptadoEn":"2026-11-11T10:00:00.000Z"}';
