import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/soporte_entrenador_controller.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/repositories/soporte_entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/soporte_entrenador_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('crea un ticket validado y conserva la lista propia en vivo', () async {
    final repository = _SoporteRepo();
    final controller = SoporteEntrenadorController(repository: repository);
    addTearDown(controller.dispose);

    controller.iniciar();
    await pumpEventQueue();

    expect(controller.tickets.map((ticket) => ticket.id), ['nuevo', 'viejo']);
    final creado = await controller.crear(
      categoria: 'asistencia',
      asunto: '  Problema con asistencia  ',
      descripcion: '  No aparece un alumno confirmado en la lista.  ',
    );

    expect(creado, isTrue);
    expect(repository.categoria, 'asistencia');
    expect(repository.asunto, 'Problema con asistencia');
    expect(
      repository.descripcion,
      'No aparece un alumno confirmado en la lista.',
    );
    expect(controller.errorFormulario, isNull);
  });

  test('no envía un ticket incompleto', () async {
    final repository = _SoporteRepo();
    final controller = SoporteEntrenadorController(repository: repository);
    addTearDown(controller.dispose);

    final creado = await controller.crear(
      categoria: 'otro',
      asunto: 'Ayuda',
      descripcion: 'Corto',
    );

    expect(creado, isFalse);
    expect(controller.errorFormulario, isNotNull);
    expect(repository.asunto, isNull);
  });

  testWidgets('muestra formulario, estado y respuesta en móvil', (tester) async {
    final auth = AuthController();
    final controller = SoporteEntrenadorController(
      repository: _SoporteRepo(),
    );
    addTearDown(auth.dispose);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SoporteEntrenadorView(auth: auth, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva solicitud'), findsOneWidget);
    expect(find.text('Mis solicitudes'), findsOneWidget);
    expect(find.text('Problema con asistencia'), findsOneWidget);
    expect(find.text('Resuelto'), findsOneWidget);
    expect(find.text('Respuesta de coordinación'), findsOneWidget);
    expect(find.text('Actualiza la página y vuelve a intentarlo.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SoporteRepo implements SoporteEntrenadorRepository {
  String? categoria;
  String? asunto;
  String? descripcion;

  @override
  Stream<List<TicketSoporte>> tickets() => Stream.value([
    TicketSoporte(
      id: 'viejo',
      asunto: 'Consulta de evento',
      categoria: 'eventos',
      descripcion: 'Necesito información sobre una solicitud.',
      autorUid: 'entrenador-1',
      autorNombre: 'Juan Pérez',
      autorRol: 'entrenador',
      estado: EstadoTicket.abierto,
      fecha: DateTime(2026, 11, 1),
    ),
    TicketSoporte(
      id: 'nuevo',
      asunto: 'Problema con asistencia',
      categoria: 'asistencia',
      descripcion: 'No puedo ver la nómina completa.',
      autorUid: 'entrenador-1',
      autorNombre: 'Juan Pérez',
      autorRol: 'entrenador',
      estado: EstadoTicket.resuelto,
      respuesta: 'Actualiza la página y vuelve a intentarlo.',
      fecha: DateTime(2026, 11, 8),
      resueltoEn: DateTime(2026, 11, 8, 12),
    ),
  ]);

  @override
  Future<String?> crear({
    required String categoria,
    required String asunto,
    required String descripcion,
  }) async {
    this.categoria = categoria;
    this.asunto = asunto;
    this.descripcion = descripcion;
    return null;
  }
}
