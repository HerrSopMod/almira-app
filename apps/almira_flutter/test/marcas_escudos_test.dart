// Marcas de pago, Plin y escudos por municipalidad.
import 'package:almira_flutter/core/widgets/escudo_municipal.dart';
import 'package:almira_flutter/core/widgets/marcas_pago.dart';
import 'package:almira_flutter/features/payments/payment_gateway.dart';
import 'package:almira_flutter/features/payments/validadores_pago.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('escudo por municipalidad', () {
    test('Lince tiene escudo y otra municipalidad no', () {
      expect(rutaEscudo(const Municipalidad(id: '1', nombre: 'Municipalidad de Lince')), 'assets/escudos/lince.png');
      expect(rutaEscudo(const Municipalidad(id: '2', nombre: 'Municipalidad Distrital de Lince')), 'assets/escudos/lince.png');
      expect(rutaEscudo(const Municipalidad(id: '3', nombre: 'Municipalidad de Miraflores')), isNull);
      expect(rutaEscudo(null), isNull);
    });

    testWidgets('sin escudo no ocupa lugar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EscudoMunicipal(Municipalidad(id: '3', nombre: 'Municipalidad de Miraflores'))),
      );
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('con escudo muestra la imagen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EscudoMunicipal(Municipalidad(id: '1', nombre: 'Municipalidad de Lince'))),
      );
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('marcas de pago', () {
    test('la marca de la tarjeta sale del primer dígito', () {
      expect(marcaDeTarjeta(''), isNull);
      expect(marcaDeTarjeta('4111 1111'), MarcaPago.visa);
      expect(marcaDeTarjeta('5555'), MarcaPago.mastercard);
      expect(marcaDeTarjeta('2221'), MarcaPago.mastercard);
      expect(marcaDeTarjeta('3782'), isNull);
    });

    testWidgets('Yape, Plin y Visa usan sus imágenes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Row(children: [
            LogoMarca(MarcaPago.yape),
            LogoMarca(MarcaPago.plin),
            LogoMarca(MarcaPago.visa),
            LogoMarca(MarcaPago.mastercard),
          ]),
        ),
      );
      expect(find.byType(Image), findsNWidgets(3));
    });
  });

  group('Plin', () {
    test('se paga con celular y código, y viaja como plin', () {
      const datos = DatosPlin(celular: '987654321', codigoAprobacion: '123456');
      expect(datos.medio, MedioPago.plin);
      expect(validarDatosPago(datos, DateTime(2026, 11, 15)), isNull);
      expect(datos.toString(), isNot(contains('987')));
    });

    test('con el celular mal escrito, no pasa', () {
      const datos = DatosPlin(celular: '12', codigoAprobacion: '123456');
      expect(validarDatosPago(datos, DateTime(2026, 11, 15)), isNotNull);
    });
  });
}
