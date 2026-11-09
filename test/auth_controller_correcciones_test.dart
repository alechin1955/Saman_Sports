import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';

void main() {
  ({bool error, bool existe, String? rol, String estado}) rol({
    String? valor = 'estudiante',
    String estado = 'activo',
    bool existe = true,
    bool error = false,
  }) {
    return (error: error, existe: existe, rol: valor, estado: estado);
  }

  test('una cuenta inactiva no entra en el login', () async {
    var salidas = 0;
    final auth = AuthController(
      entrar: (correo, clave) async => 'uid-1',
      salir: () async => salidas++,
      leerRol: (uid) async => rol(estado: 'inactivo', valor: 'entrenador'),
    );

    final destino = await auth.iniciarSesion(
      'ana@correo.unimet.edu.ve',
      'Clave123',
    );

    expect(destino, isNull);
    expect(auth.destinoActual, isNull);
    expect(auth.error, AuthController.cuentaDesactivada);
    expect(salidas, greaterThan(0));
    auth.dispose();
  });

  test('una cuenta inactiva no se restaura', () async {
    var salidas = 0;
    final auth = AuthController(
      uidSesion: () => 'uid-1',
      salir: () async => salidas++,
      leerRol: (uid) async => rol(estado: 'inactivo', valor: 'administrador'),
    );

    final resultado = await auth.rolSesionActual();

    expect(resultado.tipo, TipoResultadoRol.sinRol);
    expect(resultado.destino, isNull);
    expect(auth.error, AuthController.cuentaDesactivada);
    expect(salidas, 1);
    auth.dispose();
  });

  test('una cuenta activa entra normal', () async {
    final auth = AuthController(
      entrar: (correo, clave) async => 'uid-1',
      salir: () async {},
      leerRol: (uid) async => rol(),
    );

    final destino = await auth.iniciarSesion(
      'ana@correo.unimet.edu.ve',
      'Clave123',
    );

    expect(destino, DestinoLogin.estudiante);
    expect(auth.error, isNull);
    auth.dispose();
  });

  test('recuperar contraseña muestra el error si falla', () async {
    final auth = AuthController(
      enviarEnlace: (correo) async => AuthResponse(
        isSuccess: false,
        errorMessage: 'Sin conexión. Revisa tu internet.',
      ),
    );

    await auth.enviarEnlaceRecuperacion('ana@correo.unimet.edu.ve');

    expect(auth.enlaceEnviado, isFalse);
    expect(auth.error, 'Sin conexión. Revisa tu internet.');
    auth.dispose();
  });

  test('recuperar contraseña marca el enlace si tiene éxito', () async {
    final auth = AuthController(
      enviarEnlace: (correo) async => AuthResponse(isSuccess: true),
    );

    await auth.enviarEnlaceRecuperacion('ana@correo.unimet.edu.ve');

    expect(auth.enlaceEnviado, isTrue);
    expect(auth.error, isNull);
    auth.dispose();
  });

  test('un correo inexistente usa el mensaje genérico', () async {
    final auth = AuthController(
      enviarEnlace: (correo) async => AuthResponse(
        isSuccess: false,
        errorMessage: 'user-not-found',
      ),
    );

    await auth.enviarEnlaceRecuperacion('ana@correo.unimet.edu.ve');

    expect(auth.enlaceEnviado, isFalse);
    expect(auth.error, AuthController.enlaceGenerico);
    auth.dispose();
  });
}
