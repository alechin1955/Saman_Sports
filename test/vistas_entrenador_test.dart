import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/controllers/perfil_entrenador_controller.dart';
import 'package:saman_sports/controllers/resenas_entrenador_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/eventos_entrenador_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';
import 'package:saman_sports/repositories/resenas_entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/disciplinas_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/eventos_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/perfil_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/resenas_entrenador_view.dart';

const deporte = Deporte(
  id: 'tenis',
  nombre: 'Tenis',
  descripcion: 'Entrenamiento competitivo',
  icono: 'tenis',
  horario: 'Lunes 14:00',
  cupos: 20,
  inscritos: 8,
  entrenadorNombre: 'Juan Pérez',
  canchaId: 'c1',
  canchaNombre: 'Cancha 1',
);

const cancha = Cancha(
  id: 'c1',
  nombre: 'Cancha 1',
  ubicacion: 'Edificio deportivo',
  descripcion: '',
  activa: true,
  version: 1,
);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Disciplinas conserva el diseño del panel en móvil', (
    tester,
  ) async {
    final auth = AuthController();
    final controller = EntrenadorController(repository: _EntrenadorRepo());
    addTearDown(auth.dispose);
    addTearDown(controller.dispose);
    await _mostrar(
      tester,
      DisciplinasEntrenadorView(auth: auth, controller: controller),
    );
    expect(find.text('Tenis'), findsOneWidget);
    expect(find.text('Abrir registro de asistencia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Eventos identifica el estado de cada solicitud', (tester) async {
    final auth = AuthController();
    final eventos = EventosEntrenadorController(repository: _EventosRepo());
    final entrenador = EntrenadorController(repository: _EntrenadorRepo());
    addTearDown(auth.dispose);
    addTearDown(eventos.dispose);
    addTearDown(entrenador.dispose);
    await _mostrar(
      tester,
      EventosEntrenadorView(
        auth: auth,
        controller: eventos,
        entrenador: entrenador,
      ),
    );
    expect(find.text('Torneo interno'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Solicitar evento'), findsOneWidget);
    await tester.tap(find.text('Solicitar evento'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre del evento'), findsOneWidget);
    expect(find.text('Cancha'), findsOneWidget);
    expect(find.text('Ubicación'), findsNothing);
    expect(find.text('Capacidad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cerrar y reabrir el modal limpia el error anterior', (
    tester,
  ) async {
    final auth = AuthController();
    final eventos = EventosEntrenadorController(
      repository: _EventosRepo(errorSolicitud: 'No se pudo solicitar.'),
    );
    final entrenador = EntrenadorController(repository: _EntrenadorRepo());
    addTearDown(auth.dispose);
    addTearDown(eventos.dispose);
    addTearDown(entrenador.dispose);
    await _mostrar(
      tester,
      EventosEntrenadorView(
        auth: auth,
        controller: eventos,
        entrenador: entrenador,
      ),
    );

    await tester.tap(find.text('Solicitar evento'));
    await tester.pumpAndSettle();
    await tester.enterText(_campo('Nombre del evento'), 'Torneo interno');
    await tester.enterText(_campo('Capacidad'), '20');
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo solicitar.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solicitar evento'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo solicitar.'), findsNothing);
  });

  testWidgets('el modal avisa el choque y bloquea el envío', (tester) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final fecha =
        '${manana.year.toString().padLeft(4, '0')}-'
        '${manana.month.toString().padLeft(2, '0')}-'
        '${manana.day.toString().padLeft(2, '0')}';
    final auth = AuthController();
    final eventos = EventosEntrenadorController(
      repository: _EventosRepo(
        reservas: [
          ReservaHorario(
            id: 'r1',
            canchaId: 'c1',
            canchaNombre: 'Cancha 1',
            dia: manana.weekday,
            horaInicio: 840,
            horaFin: 960,
            fecha: fecha,
            tipo: TipoReserva.deporte,
            refId: 'd2',
            refNombre: 'Baloncesto',
            activa: true,
          ),
        ],
      ),
    );
    final entrenador = EntrenadorController(repository: _EntrenadorRepo());
    addTearDown(auth.dispose);
    addTearDown(eventos.dispose);
    addTearDown(entrenador.dispose);
    await _mostrar(
      tester,
      EventosEntrenadorView(
        auth: auth,
        controller: eventos,
        entrenador: entrenador,
      ),
    );

    await tester.tap(find.text('Solicitar evento'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Baloncesto'), findsOneWidget);
    final enviar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enviar solicitud'),
    );
    expect(enviar.onPressed, isNull);
  });

  testWidgets('Perfil muestra experiencia, estudiantes y certificaciones', (
    tester,
  ) async {
    final auth = AuthController();
    final controller = PerfilEntrenadorController(
      repository: _PerfilRepo(),
      entrenadorRepository: _EntrenadorRepo(),
    );
    addTearDown(auth.dispose);
    addTearDown(controller.dispose);
    await _mostrar(
      tester,
      PerfilEntrenadorView(auth: auth, controller: controller),
    );
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('6 años'), findsOneWidget);
    expect(find.text('8 inscritos'), findsOneWidget);
    expect(find.text('ITF Nivel 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reseñas presenta solo la retroalimentación de sus disciplinas', (
    tester,
  ) async {
    final auth = AuthController();
    final controller = ResenasEntrenadorController(repository: _ResenasRepo());
    addTearDown(auth.dispose);
    addTearDown(controller.dispose);
    await _mostrar(
      tester,
      ResenasEntrenadorView(auth: auth, controller: controller),
    );
    expect(find.text('Excelente entrenamiento.'), findsOneWidget);
    expect(find.textContaining('promedio de 1 reseñas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mostrar(WidgetTester tester, Widget vista) async {
  await tester.binding.setSurfaceSize(const Size(390, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: vista));
  await tester.pumpAndSettle();
}

class _EntrenadorRepo implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [deporte];

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => const [];
}

class _EventosRepo implements EventosEntrenadorRepository {
  _EventosRepo({this.errorSolicitud, this.reservas = const []});

  final String? errorSolicitud;
  final List<ReservaHorario> reservas;

  @override
  Stream<List<Cancha>> canchas() => Stream.value(const [cancha]);

  @override
  Stream<List<Evento>> eventos() => Stream.value([
    const Evento(
      id: 'e1',
      titulo: 'Torneo interno',
      tipo: TipoEvento.evento,
      deporteId: 'tenis',
      deporteNombre: 'Tenis',
      canchaId: 'c1',
      canchaNombre: 'Cancha 1',
      fecha: '2026-11-10',
      horaInicio: 840,
      horaFin: 960,
      descripcion: 'Cierre de semestre',
      estado: EstadoEvento.pendiente,
      creadoPorUid: 'e1',
      capacidad: 24,
    ),
  ]);

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      Stream.value(reservas);

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) async => errorSolicitud;
}

Finder _campo(String etiqueta) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == etiqueta,
);

class _PerfilRepo implements PerfilEntrenadorRepository {
  @override
  Future<PerfilEntrenador> cargar() async => const PerfilEntrenador(
    uid: 'e1',
    nombre: 'Juan',
    apellido: 'Pérez',
    correo: 'juan@unimet.edu.ve',
    telefono: '04140000000',
    disciplina: 'Tenis',
    especialidad: 'Tenis de campo',
    biografia: 'Entrenador universitario.',
    anosExperiencia: 6,
    certificaciones: ['ITF Nivel 1'],
    activo: true,
  );
}

class _ResenasRepo implements ResenasEntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [deporte];

  @override
  Stream<List<Resena>> resenas(List<String> deporteIds) => Stream.value([
    Resena(
      id: 'r1',
      autorUid: 'a1',
      autorNombre: 'Ana P.',
      disciplina: 'Tenis',
      deporteId: 'tenis',
      estrellas: 5,
      comentario: 'Excelente entrenamiento.',
      fecha: DateTime(2026, 11, 1),
    ),
  ]);
}
