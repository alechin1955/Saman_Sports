import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_evento_repository.dart';

void main() {
  late _FalsoEventos repo;
  late AdminEventoController controller;
  final hoy = DateTime(2026, 11, 11);

  setUp(() {
    repo = _FalsoEventos();
    controller = AdminEventoController(repository: repo, reloj: () => hoy);
  });

  tearDown(() => controller.dispose());

  String iso(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  DateTime conWeekday(int weekday) {
    var fecha = hoy;
    while (fecha.weekday != weekday) {
      fecha = fecha.add(const Duration(days: 1));
    }
    return fecha;
  }

  test('una fecha pasada no llama al repositorio', () async {
    final ayer = hoy.subtract(const Duration(days: 1));
    final resultado = await controller.crearEvento(
      titulo: 'Clásico',
      tipo: TipoEvento.partido,
      canchaId: 'c1',
      fecha: iso(ayer),
      horaInicio: 960,
      horaFin: 1020,
      descripcion: 'Partido',
    );

    expect(resultado, AdminEventoController.fechaPasada);
    expect(repo.creados, 0);
  });

  test(
    'un evento que pisa un deporte semanal de ese día no se guarda',
    () async {
      final miercoles = conWeekday(DateTime.wednesday);
      repo.reservas = [
        ReservaHorario(
          id: 'r1',
          canchaId: 'c1',
          canchaNombre: 'Cancha 1',
          dia: DateTime.wednesday,
          horaInicio: 960,
          horaFin: 1080,
          tipo: TipoReserva.deporte,
          refId: 'futbol',
          refNombre: 'Fútbol',
          activa: true,
        ),
      ];
      controller.observarCancha('c1');
      await Future<void>.delayed(Duration.zero);

      final resultado = await controller.crearEvento(
        titulo: 'Clásico',
        tipo: TipoEvento.partido,
        canchaId: 'c1',
        fecha: iso(miercoles),
        horaInicio: 960,
        horaFin: 1020,
        descripcion: 'Partido',
      );

      expect(resultado, contains('ocupada'));
      expect(repo.creados, 0);
    },
  );

  test('un evento en otro día sí llama al repositorio', () async {
    final jueves = conWeekday(DateTime.thursday);
    repo.reservas = [
      const ReservaHorario(
        id: 'r1',
        canchaId: 'c1',
        canchaNombre: 'Cancha 1',
        dia: DateTime.wednesday,
        horaInicio: 960,
        horaFin: 1080,
        tipo: TipoReserva.deporte,
        refId: 'futbol',
        refNombre: 'Fútbol',
        activa: true,
      ),
    ];
    controller.observarCancha('c1');
    await Future<void>.delayed(Duration.zero);

    final resultado = await controller.crearEvento(
      titulo: 'Clásico',
      tipo: TipoEvento.partido,
      canchaId: 'c1',
      fecha: iso(jueves),
      horaInicio: 960,
      horaFin: 1020,
      descripcion: 'Partido',
    );

    expect(resultado, isNull);
    expect(repo.creados, 1);
  });
}

class _FalsoEventos implements AdminEventoRepository {
  List<ReservaHorario> reservas = [];
  int creados = 0;

  @override
  Stream<List<Evento>> eventos() => Stream.value(const []);

  @override
  Stream<List<Cancha>> canchas() => Stream.value(const []);

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) {
    return Stream.value(reservas);
  }

  @override
  Future<String?> crearEvento({
    required Map<String, dynamic> datos,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
  }) async {
    creados++;
    return null;
  }

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
}
