import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/estudiante/perfil_estudiante_view.dart';

const _datos = <String, dynamic>{
  'nombre': 'María',
  'apellido': 'González',
  'cedula': 'V-28123456',
  'carnet': '20231110123',
  'telefono': '0414-1234567',
  'correo': 'maria@correo.unimet.edu.ve',
  'rol': 'estudiante',
};

void main() {
  Widget pantalla(EstudianteController controller) {
    return MaterialApp(
      home: PerfilEstudianteView(
        auth: AuthController(),
        controller: controller,
      ),
    );
  }

  Future<void> tocarGuardar(WidgetTester tester) async {
    final boton = find.widgetWithText(
      ElevatedButton,
      AppStrings.guardarCambios,
    );
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

  for (final tamano in tamanos) {
    testWidgets('muestra los datos de la cuenta y el formulario en '
        '${tamano.width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(tamano);
      final controller = EstudianteController(
        uidActual: () => 'abc',
        leer: (uid) async => _datos,
      );
      await tester.pumpWidget(pantalla(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('V-28123456'), findsOneWidget);
      expect(find.text('20231110123'), findsOneWidget);
      expect(find.text(AppStrings.guardarCambios), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  }

  testWidgets('un teléfono inválido muestra el error y no guarda', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    var guardo = false;
    final controller = EstudianteController(
      uidActual: () => 'abc',
      leer: (uid) async => _datos,
      guardar: (uid, datos) async {
        guardo = true;
        return AuthResponse(isSuccess: true);
      },
    );
    await tester.pumpWidget(pantalla(controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tocarGuardar(tester);

    expect(find.text(AppStrings.telefonoInvalido), findsOneWidget);
    expect(guardo, isFalse);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('guarda los cambios y muestra la confirmación', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    Map<String, dynamic>? guardado;
    final controller = EstudianteController(
      uidActual: () => 'abc',
      leer: (uid) async => _datos,
      guardar: (uid, datos) async {
        guardado = datos;
        return AuthResponse(isSuccess: true);
      },
    );
    await tester.pumpWidget(pantalla(controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tocarGuardar(tester);

    expect(guardado?['nombre'], 'Ana');
    expect(find.text(AppStrings.perfilActualizado), findsOneWidget);
    expect(find.text('Ana González'), findsOneWidget);

    // Deja que el SnackBar termine para no dejar temporizadores pendientes.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(null);
  });
}
