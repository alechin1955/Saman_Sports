import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_deporte_repository.dart';
import 'package:saman_sports/repositories/admin/admin_entrenador_repository.dart';
import 'package:saman_sports/views/admin/deportes_admin_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final ancho in [390.0, 1440.0]) {
    testWidgets('deportes admin en $ancho', (tester) async {
      await tester.binding.setSurfaceSize(Size(ancho, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final deportes = AdminDeporteController(repository: _Deportes());
      final entrenadores = AdminEntrenadorController(
        repository: _Entrenadores(),
      );
      addTearDown(deportes.dispose);
      addTearDown(entrenadores.dispose);
      deportes.iniciar();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeportesAdminView(
              deportes: deportes,
              entrenadores: entrenadores,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fútbol'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(AppStrings.adminNuevoDeporte));
      await tester.pumpAndSettle();
      final guardar = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, AppStrings.guardar),
      );
      expect(guardar.onPressed, isNull);
    });
  }
}

class _Deportes implements AdminDeporteRepository {
  @override
  Stream<List<Cancha>> canchas() => Stream.value(const []);
  @override
  Stream<List<Deporte>> deportes() => Stream.value(const [
    Deporte(
      id: '1',
      nombre: 'Fútbol',
      descripcion: 'Campus',
      icono: 'futbol',
      horario: 'Mié 16:00–18:00',
      cupos: 20,
      inscritos: 4,
      entrenadorNombre: 'Ana',
      canchaNombre: 'Cancha 1',
    ),
  ]);
  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      Stream.value(const []);
  @override
  Future<String?> actualizarCancha({
    required String id,
    required String nombre,
    required String ubicacion,
    required String descripcion,
    required bool activa,
  }) async => null;
  @override
  Future<String?> actualizarDeporte({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    List<Map<String, dynamic>>? franjas,
  }) async => null;
  @override
  Future<String?> asignarEntrenador({
    required String deporteId,
    required String entrenadorUid,
    required String entrenadorNombre,
  }) async => null;
  @override
  Future<String?> cambiarEstadoDeporte({
    required String id,
    required bool activo,
  }) async => null;
  @override
  Future<String?> crearCancha({
    required String nombre,
    required String ubicacion,
    required String descripcion,
  }) async => null;
  @override
  Future<String?> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  }) async => null;
}

class _Entrenadores implements AdminEntrenadorRepository {
  @override
  Future<String?> actualizar(EntrenadorAdmin datos) async => null;
  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async => null;
  @override
  Future<String?> crearCuenta({
    required String correo,
    required String clave,
    required EntrenadorAdmin datos,
  }) async => null;
  @override
  Stream<Map<String, Map<String, dynamic>>> entrenadoresPublicos() =>
      Stream.value(const {});
  @override
  Stream<Map<String, Map<String, dynamic>>> perfilesPrivados() =>
      Stream.value(const {});
}
