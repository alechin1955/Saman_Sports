import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_resena_controller.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/repositories/admin/admin_resena_repository.dart';

void main() {
  test('filtra reseñas y cambia la visibilidad', () async {
    final repo = _FalsoResenas();
    final controller = AdminResenaController(repository: repo);
    repo.lista = [
      (resena: _resena('r1'), visible: true),
      (resena: _resena('r2'), visible: false),
    ];
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    expect(controller.ocultas, 1);
    controller.cambiarFiltro(FiltroResena.ocultas);
    expect(controller.resenasFiltradas, hasLength(1));
    expect(controller.resenasFiltradas.first.resena.id, 'r2');

    final resultado = await controller.cambiarVisibilidad(
      controller.resenasFiltradas.first,
      true,
    );
    expect(resultado, isNull);
    expect(repo.ultimaVisible, isTrue);
    expect(repo.ultimoId, 'r2');
    controller.dispose();
  });
}

Resena _resena(String id) {
  return Resena(
    id: id,
    autorUid: 'est-1',
    autorNombre: 'Ana',
    disciplina: 'Fútbol',
    deporteId: 'dep-1',
    estrellas: 5,
    comentario: 'Muy bien',
    fecha: DateTime(2026, 3, 2),
  );
}

class _FalsoResenas implements AdminResenaRepository {
  List<({Resena resena, bool visible})> lista = [];
  String? ultimoId;
  bool? ultimaVisible;

  @override
  Stream<List<({Resena resena, bool visible})>> resenas() =>
      Stream.value(lista);

  @override
  Future<String?> cambiarVisibilidad({
    required String id,
    required bool visible,
  }) async {
    ultimoId = id;
    ultimaVisible = visible;
    return null;
  }
}
