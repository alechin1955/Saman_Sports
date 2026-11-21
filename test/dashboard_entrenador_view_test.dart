import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/inicio_entrenador_controller.dart';
import 'package:saman_sports/controllers/proximos_eventos_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/repositories/proximos_eventos_repository.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/historial_asistencia_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/dashboard_entrenador_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('panel entrenador adaptable a ${size.width}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = AuthController();
      final proximos = ProximosEventosController(
        modo: ModoEventos.entrenador,
        repositorio: _EventosVacios(),
      );
      addTearDown(proximos.dispose);
      final controller = InicioEntrenadorController(
        entrenadorRepository: _Entrenador(),
        perfilRepository: _Perfil(),
        historialRepository: _Historial(),
      );
      addTearDown(auth.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardEntrenadorView(
            auth: auth,
            controller: controller,
            proximos: proximos,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsAtLeastNWidgets(1));
      expect(find.text('Hola, Juan'), findsOneWidget);
      expect(find.text('Disciplinas asignadas'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width < 1024) {
        expect(find.byType(Drawer), findsNothing);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        expect(find.text('Panel del entrenador'), findsOneWidget);
      } else {
        expect(find.text('Panel del entrenador'), findsOneWidget);
      }
    });
  }
}

class _Entrenador implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [
    Deporte(
      id: 'tenis',
      nombre: 'Tenis',
      descripcion: '',
      icono: 'tenis',
      horario: 'Lunes 14:00',
      cupos: 20,
      inscritos: 8,
      entrenadorNombre: 'Juan Pérez',
    ),
  ];

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => const [];
}

class _Perfil implements PerfilEntrenadorRepository {
  @override
  Future<PerfilEntrenador> cargar() async => const PerfilEntrenador(
    uid: 'e1',
    nombre: 'Juan',
    apellido: 'Pérez',
    correo: 'juan@unimet.edu.ve',
    telefono: '',
    disciplina: 'Tenis',
    especialidad: '',
    biografia: '',
    anosExperiencia: 4,
    certificaciones: [],
    activo: true,
  );
}

class _Historial implements HistorialAsistenciaRepository {
  @override
  Future<List<SesionAsistencia>> sesiones(String deporteId) async => const [];
}

class _EventosVacios implements ProximosEventosRepository {
  @override
  Stream<List<EventoPublico>> publicos({
    required String desdeFecha,
    int limite = 20,
  }) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> inscripciones(String uid) =>
      const Stream.empty();

  @override
  Stream<String> participacion({required String eventoId, required String uid}) =>
      const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> participantes({required String eventoId}) =>
      const Stream.empty();

  @override
  Future<String?> responder({
    required String eventoId,
    required bool asistira,
    String? notificacionId,
  }) async => null;
}
