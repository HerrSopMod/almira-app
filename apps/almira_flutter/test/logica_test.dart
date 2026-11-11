import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/core/utils/formato.dart';
import 'package:almira_flutter/core/utils/plazos.dart';
import 'package:almira_flutter/features/assistant/asistente_logica.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/features/complaints/reclamos_logica.dart';
import 'package:almira_flutter/features/payments/pagos_logica.dart';
import 'package:almira_flutter/features/public_works/obras_screen.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:almira_flutter/shared/services/datos_demo.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Miércoles 11 de noviembre de 2026.
  final hoy = DateTime(2026, 11, 11, 10);

  group('formato', () {
    test('soles con dos decimales y miles', () {
      expect(soles(120.5), 'S/ 120.50');
      expect(soles(680000), 'S/ 680,000.00');
      expect(soles(0), 'S/ 0.00');
    });

    test('fechas legibles', () {
      expect(fechaLarga(DateTime(2026, 11, 30)), '30 de noviembre de 2026');
      expect(diaYMes(DateTime(2026, 11, 30)), '30 de noviembre');
      expect(fechaCorta(DateTime(2026, 10, 5)), '5 oct 2026');
    });

    test('vencimiento según hoy', () {
      expect(textoVencimiento(DateTime(2026, 11, 30), hoy), 'Vence el 30 de noviembre');
      expect(textoVencimiento(DateTime(2026, 10, 15), hoy), 'Venció el 15 de octubre');
      expect(textoVencimiento(DateTime(2026, 11, 11), hoy), 'Vence hoy');
    });

    test('iniciales y plural', () {
      expect(iniciales('Rosa Quispe Huamán'), 'RQ');
      expect(plural(1, 'obligación', 'obligaciones'), '1 obligación');
      expect(plural(2, 'obligación', 'obligaciones'), '2 obligaciones');
    });

    test('una fecha con zona pasa a la hora local; una fecha sola no cambia de día', () {
      expect(leerFecha('2026-11-30')!.day, 30);
      expect(leerFecha('2026-11-10T15:00:00+00:00')!.isUtc, isFalse);
      expect(leerFecha(''), isNull);
      expect(leerFecha('no es fecha'), isNull);
    });
  });

  group('plazo de un reclamo', () {
    Plazo? plazo(DateTime creado, {int? dias = 10, bool resuelto = false}) =>
        calcularPlazo(creadoEn: creado, plazoDias: dias, resuelto: resuelto, hoy: hoy);

    test('reclamo de hoy: quedan 9 de 10 días hábiles', () {
      final p = plazo(hoy)!;
      expect(p.estado, EstadoPlazo.dentro);
      expect(p.restantes, 9);
      expect(p.total, 10);
      expect(p.limite, DateTime.utc(2026, 11, 24));
    });

    test('nunca quedan más días que el plazo total (caso «Quedan 16 de 10»)', () {
      // El error venía de comparar con una fecha fija anterior a la creación.
      final p = plazo(DateTime(2026, 11, 20))!;
      expect(p.estado, EstadoPlazo.porConfirmar);
      expect(p.restantes, isNull);
      expect(p.etiqueta, 'Plazo por confirmar');
      for (var atras = 0; atras < 40; atras++) {
        final q = plazo(hoy.subtract(Duration(days: atras)))!;
        if (q.restantes != null) expect(q.restantes! <= q.total!, isTrue);
      }
    });

    test('por vencer, vence hoy y vencido', () {
      // Creado el jueves 29 de octubre: el décimo día hábil es el 11 de noviembre.
      expect(plazo(DateTime(2026, 10, 29))!.estado, EstadoPlazo.venceHoy);
      // Creado el lunes 2: límite el viernes 13; quedan 2 días hábiles.
      final cerca = plazo(DateTime(2026, 11, 2))!;
      expect(cerca.estado, EstadoPlazo.porVencer);
      expect(cerca.restantes, 2);
      expect(cerca.etiqueta, 'Quedan 2 días hábiles');
      final vencido = plazo(DateTime(2026, 10, 1))!;
      expect(vencido.estado, EstadoPlazo.vencido);
      expect(vencido.etiqueta, 'Plazo vencido');
    });

    test('sin plazo o sin fecha: por confirmar; resuelto: sin plazo', () {
      expect(plazo(hoy, dias: null)!.estado, EstadoPlazo.porConfirmar);
      expect(plazo(hoy, dias: 0)!.estado, EstadoPlazo.porConfirmar);
      expect(calcularPlazo(creadoEn: null, plazoDias: 10, resuelto: false, hoy: hoy)!.estado,
          EstadoPlazo.porConfirmar);
      expect(plazo(hoy, resuelto: true), isNull);
    });

    test('el fin de semana no cuenta', () {
      // Sábado 7: el primer día hábil es el lunes 9.
      expect(fechaLimite(DateTime(2026, 11, 7), 1), DateTime.utc(2026, 11, 9));
      expect(habilesEntre(DateTime(2026, 11, 6), DateTime(2026, 11, 9)), 1);
    });
  });

  group('deuda', () {
    final datos = DatosDemo.crear(hoy);

    test('el total pendiente es la suma de las obligaciones pendientes', () {
      final r = resumirDeuda(datos.deudas, hoy);
      final suma = datos.deudas.where((d) => d.pendiente).fold<double>(0, (s, d) => s + d.total);
      expect(r.total, suma);
      expect(r.total, 120.5);
      expect(r.cantidad, 2);
      expect(r.cantidadVencidas, 1);
      expect(r.montoVencido, 40);
      expect(r.montoPorVencer, 80.5);
      expect(r.montoVencido + r.montoPorVencer, r.total);
    });

    test('sin deudas: al día, sin cifras inventadas', () {
      final r = resumirDeuda(const [], hoy);
      expect(r.alDia, isTrue);
      expect(r.total, 0);
      expect(r.proximoVencimiento, isNull);
    });

    test('una deuda vigente con fecha pasada se muestra vencida', () {
      const base = Deuda(
        id: 'x',
        municipalidadId: 'm',
        vecinoId: 'v',
        tipo: TipoDeuda.arbitrios,
        concepto: 'Arbitrios',
        periodo: '',
        montoInsoluto: 10,
        interesMoratorio: 2.5,
        vencimiento: null,
        estado: EstadoDeuda.vigente,
      );
      expect(base.total, 12.5);
      expect(base.estadoAl(hoy), EstadoDeuda.vigente);
      final vencida = Deuda.deFila({
        'id': 'y',
        'tipo': 'arbitrios',
        'concepto': 'Arbitrios',
        'monto_insoluto': '10.00',
        'interes_moratorio': 0,
        'vencimiento': '2026-10-01',
        'estado': 'vigente',
      });
      expect(vencida.estadoAl(hoy), EstadoDeuda.vencida);
    });

    test('filtros', () {
      expect(filtrarDeudas(datos.deudas, FiltroDeuda.pendientes, hoy), hasLength(2));
      expect(filtrarDeudas(datos.deudas, FiltroDeuda.vencidos, hoy), hasLength(1));
      expect(filtrarDeudas(datos.deudas, FiltroDeuda.pagados, hoy), hasLength(2));
    });
  });

  group('reclamos', () {
    test('rechaza asuntos de prueba como «Jjkkk»', () {
      expect(validarAsunto('Jjkkk'), isNotNull);
      expect(validarAsunto('asdfgh qwrtp'), isNotNull);
      expect(validarAsunto('aaaaaaaa bbbb'), isNotNull);
      expect(validarAsunto(''), isNotNull);
      expect(validarAsunto('Poste sin luz'), isNull);
      expect(validarAsunto('Bache en la pista'), isNull);
    });

    test('descripción y dirección con mínimos', () {
      expect(validarDescripcion('Muy corto'), isNotNull);
      expect(validarDescripcion('El poste lleva una semana apagado.'), isNull);
      expect(validarDireccion('Jr'), isNotNull);
      expect(validarDireccion('Jr. Pumacahua 1450'), isNull);
    });

    test('sugiere la categoría por el texto', () {
      expect(clasificarReclamo('Hay un BACHE enorme'), TipoReclamo.pistasVeredas);
      expect(clasificarReclamo('poste sin luz'), TipoReclamo.alumbrado);
      expect(clasificarReclamo('Me cobraron dos veces el arbitrio'), TipoReclamo.cobroIndebido);
      expect(clasificarReclamo('otra cosa'), TipoReclamo.otro);
    });

    test('la cronología solo marca lo que los datos respaldan', () {
      Reclamo r(EstadoReclamo estado, {String? area}) => Reclamo(
            id: '1',
            municipalidadId: 'm',
            vecinoId: 'v',
            codigo: 'R-1',
            tipo: TipoReclamo.alumbrado,
            titulo: 'Poste sin luz',
            estado: estado,
            area: area,
            creadoEn: hoy,
          );
      // Recién creado: sin área todavía, no aparece «Derivado».
      final nuevo = pasosDe(r(EstadoReclamo.enAtencion));
      expect(nuevo.map((p) => p.titulo), ['Recibido', 'Clasificado', 'En atención', 'Resuelto']);
      expect(nuevo[2].estado, EstadoPaso.actual);
      expect(nuevo.last.estado, EstadoPaso.pendiente);

      final derivado = pasosDe(r(EstadoReclamo.derivado, area: 'Obras'));
      expect(derivado[2].titulo, 'Derivado al área');
      expect(derivado[2].estado, EstadoPaso.actual);
      expect(derivado[2].detalle, 'Obras');
      expect(derivado[3].estado, EstadoPaso.pendiente);

      final resuelto = pasosDe(r(EstadoReclamo.resuelto, area: 'Obras'));
      expect(resuelto.every((p) => p.estado == EstadoPaso.hecho), isTrue);
    });

    test('ubicación y foto válidas', () {
      final sin = Reclamo.deFila({'id': '1', 'foto_ruta': '', 'latitud': null});
      expect(sin.tieneFoto, isFalse);
      expect(sin.tieneUbicacion, isFalse);
      final con = Reclamo.deFila({
        'id': '2',
        'foto_ruta': 'm/u/1.jpg',
        'latitud': '-12.08',
        'longitud': -77.03,
        'plazo_dias': 10,
        'estado': 'resuelto',
        'tipo': 'limpieza',
      });
      expect(con.tieneFoto, isTrue);
      expect(con.tieneUbicacion, isTrue);
      expect(con.plazoDias, 10);
      expect(con.resuelto, isTrue);
      // Lo guardado se vuelve a leer igual (modo demostración).
      final copia = Reclamo.deFila(con.aFila());
      expect(copia.latitud, con.latitud);
      expect(copia.fotoRuta, con.fotoRuta);
      expect(copia.tipo, TipoReclamo.limpieza);
    });
  });

  group('obras', () {
    final obras = DatosDemo.crear(hoy).obras;

    test('el filtro decide la lista y los marcadores', () {
      expect(filtrarObras(obras, FiltroObra.todas), hasLength(3));
      expect(filtrarObras(obras, FiltroObra.enEjecucion), hasLength(2));
      expect(filtrarObras(obras, FiltroObra.concluidas).single.estado, EstadoObra.finalizada);
    });
  });

  group('sesión y rutas', () {
    const sinCuenta = Sesion();
    const aMedias = Sesion(cuenta: Cuenta(id: 'u'));
    const lista = Sesion(
      cuenta: Cuenta(
        id: 'u',
        ingreso: DatosIngreso(
          municipalidadId: 'm',
          consentimientos: Consentimientos(),
          aceptadoEn: '2026-11-11T00:00:00Z',
        ),
      ),
    );

    test('sin cuenta, todo lleva al ingreso', () {
      expect(redirigir(sinCuenta, Rutas.inicio), Rutas.ingreso);
      expect(redirigir(sinCuenta, Rutas.ingreso), isNull);
    });

    test('con cuenta sin terminar, va a configurar', () {
      expect(redirigir(aMedias, Rutas.inicio), Rutas.configurar);
      expect(redirigir(aMedias, Rutas.consentimiento), isNull);
    });

    test('con el ingreso completo, el recorrido inicial no reaparece', () {
      expect(redirigir(lista, Rutas.ingreso), Rutas.inicio);
      expect(redirigir(lista, Rutas.configurar), Rutas.inicio);
      expect(redirigir(lista, Rutas.consentimiento), Rutas.inicio);
      expect(redirigir(lista, Rutas.reclamos), isNull);
    });

    test('las preferencias opcionales empiezan apagadas y se guardan', () {
      const inicial = Consentimientos();
      expect([inicial.asistente, inicial.whatsapp, inicial.sms], everyElement(isFalse));
      final guardado = DatosIngreso.deJson(
        const DatosIngreso(
          municipalidadId: 'm',
          consentimientos: Consentimientos(sms: true),
          aceptadoEn: 'x',
        ).aJson(),
      )!;
      expect(guardado.consentimientos.sms, isTrue);
      expect(guardado.consentimientos.whatsapp, isFalse);
      expect(DatosIngreso.deJson(null), isNull);
      expect(DatosIngreso.deJson({'municipalidadId': 'm'}), isNull);
    });
  });

  group('asistente', () {
    final vista = crearVista(
      DatosDemo.crear(hoy),
      municipalidadId: DatosDemo.municipalidadId,
      usuarioId: DatosDemo.usuarioId,
    );

    test('responde con los datos de la cuenta, sin inventar', () {
      expect(responder('¿Cuánto debo?', vista, hoy).texto, contains('S/ 120.50'));
      expect(responder('¿Cuándo vence?', vista, hoy).texto, contains('30 de noviembre de 2026'));
      expect(responder('¿Cómo va mi reclamo?', vista, hoy).texto, contains('R-01842'));
      expect(responder('¿Qué obras hay?', vista, hoy).texto, contains('2 obras en ejecución'));
      expect(responder('cuéntame un chiste', vista, hoy).texto, contains('No tengo una respuesta'));
    });

    test('sin código vinculado no habla de deudas', () {
      final ajena = crearVista(DatosDemo.crear(hoy), municipalidadId: 'x', usuarioId: 'otro');
      expect(ajena.vecino, isNull);
      expect(responder('¿Cuánto debo?', ajena, hoy).ruta, Rutas.vincular);
    });
  });
}
