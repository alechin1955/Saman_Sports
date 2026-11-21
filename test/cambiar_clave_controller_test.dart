import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/cambiar_clave_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  test('rechaza clave corta, distinta y igual a la actual', () async {
    final controller = CambiarClaveController(
      cambiar: (actual, nueva) async => AuthResponse(isSuccess: true),
    );
    addTearDown(controller.dispose);

    expect(
      await controller.guardar(actual: '123456', nueva: '123', confirmar: '123'),
      isFalse,
    );
    expect(controller.error, AppStrings.claveCorta);

    expect(
      await controller.guardar(
        actual: '123456',
        nueva: '1234567',
        confirmar: 'otra',
      ),
      isFalse,
    );
    expect(controller.error, isNotNull);

    expect(
      await controller.guardar(
        actual: '123456',
        nueva: '123456',
        confirmar: '123456',
      ),
      isFalse,
    );
    expect(controller.error, AppStrings.claveIgualActual);
  });

  test('muestra error de clave actual y éxito', () async {
    final malo = CambiarClaveController(
      cambiar: (actual, nueva) async => AuthResponse(
        isSuccess: false,
        errorMessage: AppStrings.claveActualIncorrecta,
      ),
    );
    addTearDown(malo.dispose);
    expect(
      await malo.guardar(
        actual: '123456',
        nueva: '654321',
        confirmar: '654321',
      ),
      isFalse,
    );
    expect(malo.error, AppStrings.claveActualIncorrecta);

    final bueno = CambiarClaveController(
      cambiar: (actual, nueva) async => AuthResponse(isSuccess: true),
    );
    addTearDown(bueno.dispose);
    expect(
      await bueno.guardar(
        actual: '123456',
        nueva: '654321',
        confirmar: '654321',
      ),
      isTrue,
    );
    expect(bueno.exito, isTrue);
  });
}
