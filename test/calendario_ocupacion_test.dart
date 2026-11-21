import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_calendario_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_calendario_repository.dart';
import 'package:saman_sports/views/admin/widgets/calendario_ocupacion.dart';
import 'package:saman_sports/views/admin/widgets/tabla_desplazable.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  void tamano(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('en escritorio muestra deporte, evento y libre', (tester) async {
    tamano(tester, const Size(1440, 900));
    final controller = _nuevo();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();
    expect(find.textContaining('Lunes'), findsWidgets);
    expect(find.textContaining('Domingo'), findsWidgets);
    expect(find.textContaining('Fútbol'), findsWidgets);
    expect(_colorDe('Fútbol'), AppColors.navy);
    expect(_colorDe('Torneo'), AppColors.primary);
    expect(find.textContaining(AppStrings.adminCalendarioLibre), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en móvil lista el día sin overflow', (tester) async {
    tamano(tester, const Size(390, 844));
    final controller = _nuevo();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();
    expect(find.textContaining('08:00–09:30 · Fútbol · Deporte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el dropdown cambia de cancha', (tester) async {
    tamano(tester, const Size(1440, 900));
    final controller = _nuevo();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.tap(find.text('Norte').last);
    await tester.pump();
    expect(controller.canchaId, 'norte');
  });

  testWidgets('un ancho intermedio usa la tabla desplazable', (tester) async {
    tamano(tester, const Size(1440, 900));
    final controller = _nuevo();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 700, child: CalendarioOcupacion(controller: controller)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TablaDesplazable), findsOneWidget);
  });

  testWidgets('muestra carga, error y canchas vacías', (tester) async {
    final cargando = AdminCalendarioController(
      ahora: () => DateTime(2026, 11, 18, 10),
      repositorio: _Repo(fuenteCanchas: const Stream.empty()),
    )..iniciar();
    addTearDown(cargando.dispose);
    await tester.pumpWidget(_app(cargando));
    expect(find.byKey(const Key('calendario-cargando')), findsOneWidget);

    final error = AdminCalendarioController(
      ahora: () => DateTime(2026, 11, 18, 10),
      repositorio: _Repo(fuenteCanchas: Stream.error(StateError('x'))),
    )..iniciar();
    addTearDown(error.dispose);
    await tester.pumpWidget(_app(error));
    await tester.pump();
    expect(find.text(AppStrings.adminCalendarioError), findsOneWidget);
    expect(find.text(AppStrings.reintentar), findsOneWidget);

    final vacio = AdminCalendarioController(
      ahora: () => DateTime(2026, 11, 18, 10),
      repositorio: _Repo(
        fuenteCanchas: Stream.value(const []),
        fuenteReservas: Stream.value(const []),
      ),
    )..iniciar();
    addTearDown(vacio.dispose);
    await tester.pumpWidget(_app(vacio));
    await tester.pump();
    expect(find.text(AppStrings.adminCalendarioSinCanchas), findsOneWidget);
  });
}

Color? _colorDe(String titulo) {
  final caja = testerContainer(titulo);
  return caja.color ?? (caja.decoration as BoxDecoration?)?.color;
}

Container testerContainer(String titulo) {
  return find.byKey(ValueKey(titulo), skipOffstage: false).evaluate().single.widget
      as Container;
}

Widget _app(AdminCalendarioController controller) {
  return MaterialApp(home: Scaffold(body: CalendarioOcupacion(controller: controller)));
}

AdminCalendarioController _nuevo() {
  final controller = AdminCalendarioController(
    ahora: () => DateTime(2026, 11, 18, 10),
    repositorio: _Repo(
      fuenteCanchas: Stream.value([
        _cancha('central', 'Central'),
        _cancha('norte', 'Norte'),
      ]),
      fuenteReservas: Stream.value([
        ReservaHorario(
          id: 'd',
          canchaId: 'central',
          canchaNombre: 'Central',
          dia: 1,
          horaInicio: 480,
          horaFin: 570,
          tipo: TipoReserva.deporte,
          refId: 'd',
          refNombre: 'Fútbol',
          activa: true,
        ),
        ReservaHorario(
          id: 'e',
          canchaId: 'central',
          canchaNombre: 'Central',
          dia: 4,
          horaInicio: 600,
          horaFin: 660,
          fecha: '2026-11-19',
          tipo: TipoReserva.evento,
          refId: 'e',
          refNombre: 'Torneo',
          activa: true,
        ),
      ]),
    ),
  )..iniciar();
  return controller;
}

Cancha _cancha(String id, String nombre) {
  return Cancha(
    id: id,
    nombre: nombre,
    ubicacion: '',
    descripcion: '',
    activa: true,
    version: 1,
  );
}

class _Repo implements AdminCalendarioRepository {
  _Repo({required this.fuenteCanchas, this.fuenteReservas = const Stream.empty()});

  final Stream<List<Cancha>> fuenteCanchas;
  final Stream<List<ReservaHorario>> fuenteReservas;

  @override
  Stream<List<Cancha>> canchas() => fuenteCanchas;

  @override
  Stream<List<ReservaHorario>> reservasActivas() => fuenteReservas;
}
