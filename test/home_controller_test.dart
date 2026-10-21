import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/core/constants/datos_ejemplo.dart';

void main() {
  test('una lista vacía usa datos de ejemplo', () async {
    final controller = HomeController(
      deportesOrigen: () => Stream.value(const []),
      entrenadoresOrigen: () => Stream.value(const []),
      resenasOrigen: () => Stream.value(const []),
    );
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    expect(controller.usandoEjemplo, isTrue);
    expect(controller.deportes.length, DatosEjemplo.deportes.length);
    expect(controller.totalEntrenadores, 4);
    expect(controller.promedioEstrellas, 4.5);
    controller.dispose();
  });
}
