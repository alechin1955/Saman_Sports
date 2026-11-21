import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';

void main() {
  testWidgets('atrás no deja el spinner infinito', (tester) async {
    final sesion = StreamController<Object?>.broadcast();
    addTearDown(sesion.close);
    var llamadas = 0;
    final auth = AuthController(
      entrar: (correo, clave) async {
        sesion.add(Object());
        return 'uid-1';
      },
      uidSesion: () => 'uid-1',
      leerRol: (uid) async {
        llamadas++;
        if (llamadas == 1) {
          return (
            error: false,
            existe: true,
            rol: 'estudiante',
            estado: 'activo',
          );
        }
        return (error: true, existe: false, rol: null, estado: '');
      },
      salir: () async {},
    );
    addTearDown(auth.dispose);

    await tester.pumpWidget(SamanSportsApp(auth: auth, sesion: sesion.stream));
    sesion.add(null);
    await tester.pump();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.login);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final futuro = auth.iniciarSesion('ana@correo.unimet.edu.ve', '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await futuro;
    await tester.pump();

    tester.state<NavigatorState>(find.byType(Navigator)).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('otra-seccion')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(AppStrings.reintentar), findsOneWidget);
    expect(llamadas, greaterThanOrEqualTo(2));
  });
}
