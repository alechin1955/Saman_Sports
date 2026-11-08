import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/home_controller.dart';

void main() {
  test('una lista vacía deja el Home vacío', () async {
    final controller = HomeController(
      deportesOrigen: () => Stream.value(const []),
      entrenadoresOrigen: () => Stream.value(const []),
      resenasOrigen: () => Stream.value(const []),
    );
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    expect(controller.cargando, isFalse);
    expect(controller.deportes, isEmpty);
    expect(controller.entrenadores, isEmpty);
    expect(controller.resenas, isEmpty);
    expect(controller.promedioEstrellas, 0);
    controller.dispose();
  });

  test('la escucha sigue activa después de 5 segundos', () {
    fakeAsync((async) {
      final deportes = StreamController<List<Map<String, dynamic>>>();
      final controller = HomeController(
        deportesOrigen: () => deportes.stream,
        entrenadoresOrigen: () => Stream.value(const []),
        resenasOrigen: () => Stream.value(const []),
      );
      controller.iniciar();
      deportes.add(const [
        {'id': '1', 'nombre': 'Futbol'},
      ]);
      async.flushMicrotasks();

      expect(controller.deportes, hasLength(1));
      expect(controller.deportes.first.nombre, 'Futbol');

      async.elapse(const Duration(seconds: 6));

      deportes.add(const [
        {'id': '1', 'nombre': 'Futbol'},
        {'id': '2', 'nombre': 'Tenis'},
      ]);
      async.flushMicrotasks();

      expect(controller.deportes, hasLength(2));
      expect(controller.deportes.last.nombre, 'Tenis');
      controller.dispose();
      deportes.close();
    });
  });
}
