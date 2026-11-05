import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_deporte_repository.dart';

void main() {
  late _FalsoDeportes repo;
  late AdminDeporteController controller;

  setUp(() {
    repo = _FalsoDeportes();
    controller = AdminDeporteController(repository: repo);
  });

  tearDown(() => controller.dispose());

  test('crear el controlador no abre streams e iniciar es idempotente', () {
    expect(controller.escuchas, 0);
    expect(repo.escuchasDeportes, 0);
    controller.iniciar();
    controller.iniciar();
    expect(controller.escuchas, 1);
    expect(repo.escuchasDeportes, 1);
  });

  test('crear un deporte sin cancha no llama al repositorio', () async {
    final resultado = await controller.crearDeporte(
      nombre: 'Fútbol',
      descripcion: 'Campus',
      icono: 'futbol',
      cupos: 20,
      canchaId: '',
      franjas: [const FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080)],
    );

    expect(resultado, AdminDeporteController.canchaObligatoria);
    expect(repo.crearDeportes, 0);
  });

  test('una franja que choca no llega al repositorio', () async {
    repo.reservas = [
      const ReservaHorario(
        id: 'r1',
        canchaId: 'c1',
        canchaNombre: 'Cancha 1',
        dia: 3,
        horaInicio: 960,
        horaFin: 1080,
        tipo: TipoReserva.deporte,
        refId: 'otro',
        refNombre: 'Fútbol',
        activa: true,
      ),
    ];
    controller.observarCancha('c1');
    await Future<void>.delayed(Duration.zero);

    final resultado = await controller.crearDeporte(
      nombre: 'Básquet',
      descripcion: 'Gimnasio',
      icono: 'baloncesto',
      cupos: 12,
      canchaId: 'c1',
      franjas: [const FranjaHorario(dia: 3, horaInicio: 1000, horaFin: 1100)],
    );

    expect(resultado, contains('ocupada'));
    expect(repo.crearDeportes, 0);
  });

  test('la misma franja en otra cancha sí llama al repositorio', () async {
    repo.reservas = [
      const ReservaHorario(
        id: 'r1',
        canchaId: 'c1',
        canchaNombre: 'Cancha 1',
        dia: 3,
        horaInicio: 960,
        horaFin: 1080,
        tipo: TipoReserva.deporte,
        refId: 'otro',
        refNombre: 'Fútbol',
        activa: true,
      ),
    ];
    controller.observarCancha('c1');
    await Future<void>.delayed(Duration.zero);

    final resultado = await controller.crearDeporte(
      nombre: 'Básquet',
      descripcion: 'Gimnasio',
      icono: 'baloncesto',
      cupos: 12,
      canchaId: 'c2',
      franjas: [const FranjaHorario(dia: 3, horaInicio: 960, horaFin: 1080)],
    );

    expect(resultado, isNull);
    expect(repo.crearDeportes, 1);
  });

  test('los bordes que se tocan están permitidos', () async {
    repo.reservas = [
      const ReservaHorario(
        id: 'r1',
        canchaId: 'c1',
        canchaNombre: 'Cancha 1',
        dia: 1,
        horaInicio: 480,
        horaFin: 600,
        tipo: TipoReserva.deporte,
        refId: 'otro',
        refNombre: 'Fútbol',
        activa: true,
      ),
    ];
    controller.observarCancha('c1');
    await Future<void>.delayed(Duration.zero);

    final resultado = await controller.crearDeporte(
      nombre: 'Tenis',
      descripcion: 'Cancha',
      icono: 'tenis',
      cupos: 8,
      canchaId: 'c1',
      franjas: [const FranjaHorario(dia: 1, horaInicio: 600, horaFin: 720)],
    );

    expect(resultado, isNull);
    expect(repo.crearDeportes, 1);
  });

  test('editar sin cambiar horario no choca consigo mismo', () async {
    repo.reservas = [
      const ReservaHorario(
        id: 'r1',
        canchaId: 'c1',
        canchaNombre: 'Cancha 1',
        dia: 1,
        horaInicio: 960,
        horaFin: 1080,
        tipo: TipoReserva.deporte,
        refId: 'dep-1',
        refNombre: 'Fútbol',
        activa: true,
      ),
    ];
    controller.observarCancha('c1');
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.validarHorario(
        canchaId: 'c1',
        franjas: [const FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080)],
        ignorarDeporteId: 'dep-1',
      ),
      isNull,
    );
  });

  test('filtra y busca deportes', () async {
    repo.lista = [
      const Deporte(
        id: '1',
        nombre: 'Fútbol',
        descripcion: '',
        icono: 'futbol',
        horario: '',
        cupos: 10,
        inscritos: 1,
        entrenadorNombre: 'Ana',
        activo: true,
      ),
      const Deporte(
        id: '2',
        nombre: 'Tenis',
        descripcion: '',
        icono: 'tenis',
        horario: '',
        cupos: 8,
        inscritos: 0,
        entrenadorNombre: 'Luis',
        activo: false,
      ),
    ];
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    controller.cambiarFiltro(FiltroDeporte.inactivos);
    expect(controller.deportesFiltrados.map((d) => d.nombre), ['Tenis']);
    controller.cambiarFiltro(FiltroDeporte.todos);
    controller.buscar('ana');
    expect(controller.deportesFiltrados.map((d) => d.nombre), ['Fútbol']);
  });
}

class _FalsoDeportes implements AdminDeporteRepository {
  int escuchasDeportes = 0;
  int crearDeportes = 0;
  List<Deporte> lista = [];
  List<ReservaHorario> reservas = [];

  @override
  Stream<List<Deporte>> deportes() {
    escuchasDeportes++;
    return Stream.value(lista);
  }

  @override
  Stream<List<Cancha>> canchas() => Stream.value(const []);

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) {
    return Stream.value(reservas);
  }

  @override
  Future<String?> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  }) async {
    crearDeportes++;
    return null;
  }

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
}
