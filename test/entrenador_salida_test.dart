import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/asistencia_entrenador_view.dart';

const alumno = AlumnoInscrito(
  inscripcionId: 'i1',
  uid: 'u1',
  nombre: 'Ana Pérez',
  carnet: '20261001',
  correo: '',
);

class _Nomina implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => [
    const Deporte(
      id: 'd1',
      nombre: 'Tenis',
      descripcion: '',
      icono: 'tenis',
      horario: 'Lun 14:00',
      cupos: 20,
      inscritos: 1,
      entrenadorNombre: 'Diego',
    ),
  ];
  @override
  Future<List<AlumnoInscrito>> inscritos(String id) async => [alumno];
}

class _DosNominas implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [
    Deporte(
      id: 'd1',
      nombre: 'Tenis',
      descripcion: '',
      icono: 'tenis',
      horario: 'Lun 14:00',
      cupos: 20,
      inscritos: 1,
      entrenadorNombre: 'Diego',
    ),
    Deporte(
      id: 'd2',
      nombre: 'Natación',
      descripcion: '',
      icono: 'natacion',
      horario: 'Mar 16:00',
      cupos: 20,
      inscritos: 1,
      entrenadorNombre: 'Diego',
    ),
  ];

  @override
  Future<List<AlumnoInscrito>> inscritos(String id) async => [
    AlumnoInscrito(
      inscripcionId: id == 'd1' ? 'i1' : 'i2',
      uid: id == 'd1' ? 'u1' : 'u2',
      nombre: id == 'd1' ? 'Ana Pérez' : 'Luis Gómez',
      carnet: id == 'd1' ? '20261001' : '20261002',
      correo: '',
    ),
  ];
}

class _Asistencia implements AsistenciaRepository {
  @override
  Future<Map<String, EstadoAsistencia>> leer(String id, DateTime fecha) async =>
      {};
  @override
  Future<void> guardar(
    String id,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  ) async {}
}

class _Auth extends AuthController {
  bool cerro = false;
  @override
  Future<void> cerrarSesion() async {
    cerro = true;
  }
}

void main() {
  testWidgets(
    'cancelar salida conserva borrador y confirmar permite cerrar sesión',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = _Auth();
      final nomina = EntrenadorController(repository: _Nomina());
      final asistencia = AsistenciaController(repository: _Asistencia());
      addTearDown(auth.dispose);
      addTearDown(nomina.dispose);
      addTearDown(asistencia.dispose);
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/entrenador/asistencia',
          routes: {
            '/': (_) => const Scaffold(body: Text('Inicio público')),
            '/entrenador/asistencia': (_) => AsistenciaEntrenadorView(
              auth: auth,
              controller: nomina,
              asistencia: asistencia,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      asistencia.marcar('i1', EstadoAsistencia.presente);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Tienes asistencia sin guardar'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(auth.cerro, isFalse);
      expect(asistencia.cambios, isTrue);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar y salir'));
      await tester.pumpAndSettle();
      expect(auth.cerro, isTrue);
      expect(asistencia.cambios, isFalse);
      expect(find.text('Inicio público'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('retroceder conserva el borrador hasta confirmar descarte', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final auth = _Auth();
    final nomina = EntrenadorController(repository: _Nomina());
    final asistencia = AsistenciaController(repository: _Asistencia());
    addTearDown(auth.dispose);
    addTearDown(nomina.dispose);
    addTearDown(asistencia.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Pantalla anterior')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => AsistenciaEntrenadorView(
          auth: auth,
          controller: nomina,
          asistencia: asistencia,
        ),
      ),
    );
    await tester.pumpAndSettle();
    asistencia.marcar('i1', EstadoAsistencia.ausente);
    await tester.pumpAndSettle();
    navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Tienes asistencia sin guardar'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(asistencia.cambios, isTrue);
    expect(find.text('Asistencia'), findsOneWidget);
    navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar y salir'));
    await tester.pumpAndSettle();
    expect(asistencia.cambios, isFalse);
    expect(find.text('Pantalla anterior'), findsOneWidget);
    expect(auth.cerro, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Volver a disciplinas también protege el borrador', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _Auth();
    final nomina = EntrenadorController(repository: _Nomina());
    final asistencia = AsistenciaController(repository: _Asistencia());
    addTearDown(auth.dispose);
    addTearDown(nomina.dispose);
    addTearDown(asistencia.dispose);
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/entrenador/asistencia',
        routes: {
          '/entrenador/asistencia': (_) => AsistenciaEntrenadorView(
            auth: auth,
            controller: nomina,
            asistencia: asistencia,
          ),
          '/entrenador/disciplinas': (_) =>
              const Scaffold(body: Text('Disciplinas destino')),
        },
      ),
    );
    await tester.pumpAndSettle();
    asistencia.marcar('i1', EstadoAsistencia.presente);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a disciplinas'));
    await tester.pumpAndSettle();
    expect(find.text('Tienes asistencia sin guardar'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.text('Asistencia'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Volver a disciplinas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar y salir'));
    await tester.pumpAndSettle();
    expect(find.text('Disciplinas destino'), findsOneWidget);
    expect(asistencia.cambios, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelar cambio de disciplina restaura selector y nómina originales',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = _Auth();
      final nomina = EntrenadorController(repository: _DosNominas());
      final asistencia = AsistenciaController(repository: _Asistencia());
      addTearDown(auth.dispose);
      addTearDown(nomina.dispose);
      addTearDown(asistencia.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: AsistenciaEntrenadorView(
            auth: auth,
            controller: nomina,
            asistencia: asistencia,
          ),
        ),
      );
      await tester.pumpAndSettle();
      asistencia.marcar('i1', EstadoAsistencia.presente);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Natación').last);
      await tester.pumpAndSettle();
      expect(find.text('Tienes asistencia sin guardar'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();

      final selector = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      final estadoSelector = tester.state<FormFieldState<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(nomina.seleccionId, 'd1');
      expect(selector.initialValue, 'd1');
      expect(estadoSelector.value, 'd1');
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Luis Gómez'), findsNothing);
      expect(asistencia.deporteId, 'd1');
      expect(asistencia.estados['i1'], EstadoAsistencia.presente);
      expect(tester.takeException(), isNull);
    },
  );
}
