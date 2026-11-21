import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/datos_registro.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/identificadores.dart';

void main() {
  const datos = DatosRegistro(
    nombre: 'Ana',
    apellido: 'Perez',
    cedula: 'v-12345678',
    carnet: '20201111',
    telefono: '04121234567',
    correo: 'ana@correo.unimet.edu.ve',
    clave: '123456',
  );

  test('normaliza cédula y carnet', () {
    expect(cedulaNormalizada(' v-12345678 '), 'V-12345678');
    expect(carnetNormalizado(' 20201111 '), '20201111');
    expect(datos.toMap()['cedula'], 'V-12345678');
    expect(datos.toMap()['carnet'], '20201111');
  });

  test('cédula repetida borra la cuenta creada', () async {
    var borro = false;
    final auth = AuthController(
      crearCuenta: (_) async => (isSuccess: true, uid: 'u1', error: null),
      borrarCuenta: () async => borro = true,
      crearPerfil: ({required uid, required datos}) async => AuthResponse(
        isSuccess: false,
        errorMessage: AppStrings.cedulaYaRegistrada,
      ),
    );
    addTearDown(auth.dispose);

    final ok = await auth.registrarEstudiante(datos);

    expect(ok, isFalse);
    expect(auth.error, AppStrings.cedulaYaRegistrada);
    expect(borro, isTrue);
  });

  test('registro exitoso deja el destino en estudiante', () async {
    var inicioSesionAutomatico = false;
    final auth = AuthController(
      crearCuenta: (_) async => (isSuccess: true, uid: 'u1', error: null),
      borrarCuenta: () async {},
      crearPerfil: ({required uid, required datos}) async =>
          AuthResponse(isSuccess: true),
      iniciarSesionRegistro: (correo, clave) async {
        inicioSesionAutomatico = true;
        return (uid: 'u1', error: null);
      },
    );
    addTearDown(auth.dispose);

    final ok = await auth.registrarEstudiante(datos);

    expect(ok, isTrue);
    expect(auth.destinoActual, DestinoLogin.estudiante);
    expect(inicioSesionAutomatico, isTrue);
  });

  test(
    'traduce el error cuando Firebase tiene deshabilitado el registro',
    () async {
      final auth = AuthController(
        crearCuenta: (_) async => (
          isSuccess: false,
          uid: null,
          error: 'operation-not-allowed: Operation not allowed.',
        ),
      );
      addTearDown(auth.dispose);

      final ok = await auth.registrarEstudiante(datos);

      expect(ok, isFalse);
      expect(auth.error, AppStrings.registroNoHabilitado);
    },
  );

  test('muestra el detalle cuando falla inesperadamente el registro', () async {
    final auth = AuthController(
      crearCuenta: (_) async => throw StateError('fallo de prueba'),
    );
    addTearDown(auth.dispose);

    final ok = await auth.registrarEstudiante(datos);

    expect(ok, isFalse);
    expect(auth.error, contains('fallo de prueba'));
    expect(auth.error, isNot(AppStrings.errorInesperado));
  });
}
