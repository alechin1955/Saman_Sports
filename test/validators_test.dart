import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/validators.dart';

void main() {
  group('correo de estudiante', () {
    test('acepta un correo @correo.unimet.edu.ve', () {
      expect(
        Validators.correoEstudiante('ana@correo.unimet.edu.ve'),
        isNull,
      );
      expect(
        Validators.esCorreoEstudiante('  ANA@correo.unimet.edu.ve  '),
        isTrue,
      );
    });

    test('rechaza correos que no terminan en el dominio de estudiante', () {
      expect(
        Validators.correoEstudiante('ana@unimet.edu.ve'),
        AppStrings.soloCorreoEstudiante,
      );
      expect(
        Validators.correoEstudiante('ana@gmail.com'),
        AppStrings.soloCorreoEstudiante,
      );
      expect(
        Validators.correoEstudiante('ana@correo.unimet.edu.ve.com'),
        AppStrings.soloCorreoEstudiante,
      );
    });
  });

  group('clave y teléfono', () {
    test('rechaza una contraseña de 5 caracteres', () {
      expect(Validators.clave('12345'), AppStrings.claveCorta);
    });

    test('acepta el teléfono 0414-1234567', () {
      expect(Validators.telefono('0414-1234567'), isNull);
    });
  });
}
