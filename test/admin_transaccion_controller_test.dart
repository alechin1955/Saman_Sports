import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/repositories/admin/admin_transaccion_repository.dart';
import 'package:saman_sports/repositories/admin/resolutor_nombres_repository.dart';

void main() {
  test('filtra historial por fecha, módulo y rol', () async {
    final repo = _FalsoHistorial();
    final controller = AdminTransaccionController(repository: repo);
    repo.lista = [
      _tx('1', DateTime(2026, 3, 1), 'pagos', 'administrador'),
      _tx('2', DateTime(2026, 3, 15), 'eventos', 'administrador'),
      _tx('3', DateTime(2026, 3, 20), 'pagos', 'entrenador'),
    ];
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    controller.filtrar(
      desde: DateTime(2026, 3, 10),
      hasta: DateTime(2026, 3, 31),
      modulo: 'pagos',
      rol: 'entrenador',
    );
    expect(controller.transaccionesFiltradas.map((t) => t.id), ['3']);
    controller.limpiarFiltros();
    expect(controller.transaccionesFiltradas, hasLength(3));
    expect(AdminTransaccionController.modulos, contains('pagos'));
    controller.dispose();
  });

  test('traduce registros viejos, cachea y respeta legible', () async {
    const inscripcion =
        'UID12345678901234567890_DEP1234567890123456';
    const pago = 'PAGO1234567890123456';
    const alumno = 'UID12345678901234567890';
    const desconocido = 'XXXX12345678901234567890';
    final resolutor = _Resolutor({
      'usuarios': {alumno: 'Ana Pérez'},
      'deportes': {'DEP1234567890123456': 'Fútbol'},
      'pagos': {pago: 'del período 2026-1'},
    });
    final repo = _FalsoHistorial();
    final frase =
        'La fecha es la del momento de verificar, no una fecha bancaria.';
    repo.lista = [
      _tx(
        'i',
        DateTime(2026, 1, 1),
        'inscripciones',
        'administrador',
        descripcion: 'Cambió a pendiente la inscripción $inscripcion',
      ),
      _tx(
        'p',
        DateTime(2026, 1, 2),
        'pagos',
        'administrador',
        descripcion:
            'Verificó el pago $pago y dejó solvente a $alumno. $frase',
      ),
      _tx(
        'x',
        DateTime(2026, 1, 3),
        'pagos',
        'administrador',
        descripcion: 'Marcó el pago $desconocido',
      ),
      _tx(
        'l',
        DateTime(2026, 1, 4),
        'pagos',
        'administrador',
        descripcion: 'Ya legible $pago',
        legible: true,
      ),
      _tx(
        'c',
        DateTime(2026, 1, 5),
        'pagos',
        'administrador',
        descripcion: 'Otro pago $pago',
      ),
    ];
    final controller = AdminTransaccionController(
      repository: repo,
      resolutor: resolutor,
    );
    addTearDown(controller.dispose);
    controller.iniciar();
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(
      controller.descripcionVisible(repo.lista[0]),
      'Cambió a pendiente la inscripción de Ana Pérez en Fútbol',
    );
    final pagoVisible = controller.descripcionVisible(repo.lista[1]);
    expect(pagoVisible, isNot(contains(pago)));
    expect(pagoVisible, isNot(contains(alumno)));
    expect(pagoVisible, isNot(contains(frase)));
    expect(
      controller.descripcionVisible(repo.lista[2]),
      contains(AppStrings.adminRegistroNoDisponible),
    );
    expect(controller.descripcionVisible(repo.lista[3]), 'Ya legible $pago');
    expect(resolutor.llamadas[pago], 1);

    final talCual = AdminTransaccionController(repository: _FalsoHistorial());
    addTearDown(talCual.dispose);
    expect(
      talCual.descripcionVisible(repo.lista[1]),
      repo.lista[1].descripcion,
    );
  });
}

Transaccion _tx(
  String id,
  DateTime fecha,
  String modulo,
  String rol, {
  String descripcion = 'Cambio',
  bool legible = false,
}) {
  return Transaccion(
    id: id,
    fecha: fecha,
    usuarioUid: 'u1',
    usuarioNombre: 'Admin',
    rol: rol,
    accion: 'crear',
    modulo: modulo,
    descripcion: descripcion,
    legible: legible,
  );
}

class _Resolutor implements ResolutorNombresAdmin {
  _Resolutor(this.datos);

  final Map<String, Map<String, String>> datos;
  final Map<String, int> llamadas = {};

  @override
  Future<String?> nombre(String coleccion, String id) async {
    llamadas[id] = (llamadas[id] ?? 0) + 1;
    return datos[coleccion]?[id];
  }
}

class _FalsoHistorial implements AdminTransaccionRepository {
  List<Transaccion> lista = [];

  @override
  Stream<List<Transaccion>> transacciones() => Stream.value(lista);
}
