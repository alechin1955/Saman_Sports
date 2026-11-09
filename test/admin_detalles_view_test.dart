import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/controllers/admin/admin_soporte_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/repositories/admin/admin_deporte_repository.dart';
import 'package:saman_sports/repositories/admin/admin_entrenador_repository.dart';
import 'package:saman_sports/repositories/admin/admin_estudiante_repository.dart';
import 'package:saman_sports/repositories/admin/admin_evento_repository.dart';
import 'package:saman_sports/repositories/admin/admin_soporte_repository.dart';
import 'package:saman_sports/views/admin/deportes_admin_view.dart';
import 'package:saman_sports/views/admin/entrenadores_admin_view.dart';
import 'package:saman_sports/views/admin/estudiantes_admin_view.dart';
import 'package:saman_sports/views/admin/eventos_admin_view.dart';
import 'package:saman_sports/views/admin/soporte_admin_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('el diálogo dice desactivar o reactivar según el deporte', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deportes = AdminDeporteController(repository: _Deportes());
    final entrenadores = AdminEntrenadorController(repository: _Entrenadores());
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

    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, AppStrings.adminDesactivar),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Desactivar deporte'), findsOneWidget);
    expect(
      find.text('El deporte dejará de mostrarse en el catálogo.'),
      findsOneWidget,
    );
    await tester.tap(find.text(AppStrings.cancelar));
    await tester.pumpAndSettle();

    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, AppStrings.adminReactivar),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Reactivar deporte'), findsOneWidget);
    expect(find.text(AppStrings.adminReactivar), findsWidgets);
  });

  testWidgets('el filtro Cancelados muestra solo los cancelados', (
    tester,
  ) async {
    final eventos = AdminEventoController(repository: _Eventos());
    addTearDown(eventos.dispose);
    eventos.iniciar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EventosAdminView(eventos: eventos)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.adminCancelados));
    await tester.pumpAndSettle();

    expect(find.text('Torneo cancelado'), findsOneWidget);
    expect(find.text('Torneo pendiente'), findsNothing);
  });

  testWidgets('soporte muestra la categoría y la respuesta resuelta', (
    tester,
  ) async {
    final soporte = AdminSoporteController(repository: _Soporte());
    addTearDown(soporte.dispose);
    soporte.iniciar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SoporteAdminView(soporte: soporte)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cuenta y acceso'), findsOneWidget);
    expect(find.text('cuenta'), findsNothing);
    expect(find.text('${AppStrings.adminRespuesta}: Listo'), findsOneWidget);
    expect(
      find.text('${AppStrings.adminFecha}: 08/11/2026 10:00'),
      findsOneWidget,
    );
  });

  testWidgets('Editar cabe en el ancho útil de una ventana de 1280', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1020, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entrenadores = AdminEntrenadorController(repository: _Entrenadores());
    final deportes = AdminDeporteController(repository: _Deportes());
    final estudiantes = AdminEstudianteController(repository: _Estudiantes());
    addTearDown(entrenadores.dispose);
    addTearDown(deportes.dispose);
    addTearDown(estudiantes.dispose);
    entrenadores.iniciar();
    estudiantes.iniciar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntrenadoresAdminView(
            entrenadores: entrenadores,
            deportes: deportes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _cabe(tester, AppStrings.editar);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EstudiantesAdminView(estudiantes: estudiantes)),
      ),
    );
    await tester.pumpAndSettle();
    _cabe(tester, AppStrings.editar);
  });
}

void _cabe(WidgetTester tester, String texto) {
  final rect = tester.getRect(find.text(texto).first);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(1020));
  expect(tester.takeException(), isNull);
}

class _Deportes implements AdminDeporteRepository {
  @override
  Stream<List<Deporte>> deportes() => Stream.value([
    _deporte(activo: true, nombre: 'Tenis'),
    _deporte(activo: false, nombre: 'Futbol'),
  ]);
  @override
  Stream<List<Cancha>> canchas() => const Stream.empty();
  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      const Stream.empty();
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

Deporte _deporte({required bool activo, required String nombre}) {
  return Deporte(
    id: nombre,
    nombre: nombre,
    descripcion: '',
    icono: 'otro',
    horario: '',
    cupos: 10,
    inscritos: 0,
    entrenadorNombre: '',
    activo: activo,
  );
}

class _Entrenadores implements AdminEntrenadorRepository {
  @override
  Stream<Map<String, Map<String, dynamic>>> entrenadoresPublicos() {
    return Stream.value({
      'e1': {
        'nombre': 'Juan',
        'apellido': 'Pérez',
        'disciplina': 'Tenis',
        'activo': true,
        'especialidad': 'Tenis',
        'anosExperiencia': 4,
      },
    });
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> perfilesPrivados() {
    return Stream.value({
      'e1': {
        'correo': 'juan@unimet.edu.ve',
        'cedula': 'V-1',
        'telefono': '0412',
      },
    });
  }

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
}

class _Eventos implements AdminEventoRepository {
  @override
  Stream<List<Evento>> eventos() => Stream.value([
    _evento('Torneo pendiente', EstadoEvento.pendiente),
    _evento('Torneo cancelado', EstadoEvento.cancelado),
  ]);
  @override
  Stream<List<Cancha>> canchas() => const Stream.empty();
  @override
  Stream<List<Deporte>> deportes() => const Stream.empty();
  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      const Stream.empty();
  @override
  Future<String?> actualizarEvento({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    String? fecha,
    int? horaInicio,
    int? horaFin,
  }) async => null;
  @override
  Future<String?> cambiarEstadoEvento({
    required String id,
    required String estado,
  }) async => null;
  @override
  Future<String?> crearEvento({
    required Map<String, dynamic> datos,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
  }) async => null;
  @override
  Future<String?> notificarInscritos({
    required String deporteId,
    required String titulo,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    required String canchaNombre,
    required bool reemplazaPractica,
  }) async => null;
}

Evento _evento(String titulo, EstadoEvento estado) {
  return Evento(
    id: titulo,
    titulo: titulo,
    tipo: TipoEvento.evento,
    canchaId: 'c1',
    canchaNombre: 'Norte',
    fecha: '2026-11-08',
    horaInicio: 8,
    horaFin: 9,
    descripcion: '',
    estado: estado,
    creadoPorUid: 'admin',
  );
}

class _Soporte implements AdminSoporteRepository {
  @override
  Stream<List<TicketSoporte>> tickets() => Stream.value([
    TicketSoporte(
      id: 't1',
      asunto: 'No entro',
      categoria: 'cuenta',
      descripcion: 'Falla el acceso',
      autorUid: 'e1',
      autorNombre: 'Juan',
      autorRol: 'entrenador',
      estado: EstadoTicket.resuelto,
      fecha: DateTime(2026, 11, 1, 9),
      respuesta: 'Listo',
      resueltoEn: DateTime(2026, 11, 8, 10),
    ),
  ]);

  @override
  Future<String?> responder({
    required String id,
    required String respuesta,
  }) async => null;
}

class _Estudiantes implements AdminEstudianteRepository {
  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value([
    const Estudiante(
      uid: 'a1',
      cedula: 'V-1',
      nombre: 'Ana',
      apellido: 'Pérez',
      correo: 'ana@correo.unimet.edu.ve',
      carnet: '20201111',
      telefono: '04141234567',
      activo: true,
      solvente: true,
    ),
  ]);
  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) async => null;
  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async => null;
}
