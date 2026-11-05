import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/repositories/admin/admin_estudiante_repository.dart';

void main() {
  test('filtra solventes, pendientes e inactivos y busca por carnet', () async {
    final repo = _FalsoEstudiantes();
    final controller = AdminEstudianteController(repository: repo);
    repo.lista = [
      _estudiante('1', apellido: 'Pérez', carnet: '111', solvente: true),
      _estudiante('2', apellido: 'Rojas', carnet: '222', solvente: false),
      _estudiante('3', apellido: 'Abad', carnet: '333', activo: false),
    ];
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    controller.cambiarFiltro(FiltroEstudiante.solventes);
    expect(controller.estudiantesFiltrados.map((e) => e.uid), ['1']);
    controller.cambiarFiltro(FiltroEstudiante.pendientes);
    expect(controller.estudiantesFiltrados.map((e) => e.uid), ['3', '2']);
    controller.cambiarFiltro(FiltroEstudiante.inactivos);
    expect(controller.estudiantesFiltrados.map((e) => e.uid), ['3']);
    controller.cambiarFiltro(FiltroEstudiante.todos);
    controller.buscar('222');
    expect(controller.estudiantesFiltrados.map((e) => e.uid), ['2']);
    controller.dispose();
  });
}

Estudiante _estudiante(
  String uid, {
  required String apellido,
  required String carnet,
  bool activo = true,
  bool solvente = false,
}) {
  return Estudiante(
    uid: uid,
    cedula: 'V-1',
    nombre: 'Ana',
    apellido: apellido,
    correo: 'ana@correo.unimet.edu.ve',
    carnet: carnet,
    telefono: '04141234567',
    activo: activo,
    solvente: solvente,
  );
}

class _FalsoEstudiantes implements AdminEstudianteRepository {
  List<Estudiante> lista = [];

  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value(lista);

  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async {
    return null;
  }
}
