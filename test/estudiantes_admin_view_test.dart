import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/repositories/admin/admin_estudiante_repository.dart';
import 'package:saman_sports/views/admin/estudiantes_admin_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final ancho in [390.0, 1440.0]) {
    testWidgets('filtros de estudiantes en $ancho', (tester) async {
      await tester.binding.setSurfaceSize(Size(ancho, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final panel = AdminEstudianteController(repository: _Estudiantes());
      addTearDown(panel.dispose);
      panel.iniciar();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EstudiantesAdminView(estudiantes: panel)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('V-12345678'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(AppStrings.adminPendientes));
      await tester.pumpAndSettle();

      expect(find.text('Ana Pérez'), findsNothing);
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('V-12345678'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Estudiantes implements AdminEstudianteRepository {
  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value(const [
    Estudiante(
      uid: 'ana',
      cedula: 'V-12345678',
      nombre: 'Ana',
      apellido: 'Pérez',
      correo: 'ana@correo.unimet.edu.ve',
      carnet: '20201111',
      telefono: '04120000000',
      activo: true,
      solvente: true,
    ),
    Estudiante(
      uid: 'luis',
      cedula: 'V-87654321',
      nombre: 'Luis',
      apellido: 'Gómez',
      correo: 'luis@correo.unimet.edu.ve',
      carnet: '20202222',
      telefono: '04121111111',
      activo: true,
      solvente: false,
    ),
  ]);

  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async => null;
}
