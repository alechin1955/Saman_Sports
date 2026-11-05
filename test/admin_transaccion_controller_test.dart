import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/repositories/admin/admin_transaccion_repository.dart';

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
}

Transaccion _tx(String id, DateTime fecha, String modulo, String rol) {
  return Transaccion(
    id: id,
    fecha: fecha,
    usuarioUid: 'u1',
    usuarioNombre: 'Admin',
    rol: rol,
    accion: 'crear',
    modulo: modulo,
    descripcion: 'Cambio',
  );
}

class _FalsoHistorial implements AdminTransaccionRepository {
  List<Transaccion> lista = [];

  @override
  Stream<List<Transaccion>> transacciones() => Stream.value(lista);
}
