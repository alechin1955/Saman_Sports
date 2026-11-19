import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_deporte_repository.dart';
import 'package:saman_sports/views/admin/cancha_form_dialog.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('el diálogo muestra el error y no se cierra', (tester) async {
    final panel = AdminDeporteController(repository: _Canchas());
    addTearDown(panel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CanchaFormDialog(deportes: panel),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.guardar));
    await tester.pumpAndSettle();

    expect(find.text(AdminDeporteController.nombreObligatorio), findsOneWidget);
    expect(find.text(AppStrings.adminNuevaCancha), findsOneWidget);
    final texto = tester.widget<Text>(
      find.text(AdminDeporteController.nombreObligatorio),
    );
    expect(texto.style?.color, AppColors.error);
  });
}

class _Canchas implements AdminDeporteRepository {
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
  Stream<List<Cancha>> canchas() => const Stream.empty();

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
  }) async => 'No se pudo guardar la cancha.';

  @override
  Future<String?> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  }) async => null;

  @override
  Stream<List<Deporte>> deportes() => const Stream.empty();

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      const Stream.empty();
}
