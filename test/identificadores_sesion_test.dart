import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/identificadores.dart';

void main() {
  const ana = AlumnoIdentificador(
    uid: 'ana',
    nombre: 'Ana',
    apellido: 'Pérez',
    cedula: ' v-12345678 ',
    carnet: ' 20201111 ',
  );
  const luis = AlumnoIdentificador(
    uid: 'luis',
    nombre: 'Luis',
    apellido: 'Gómez',
    cedula: 'V-12345678',
    carnet: '20202222',
  );

  test('estudiante sin índices crea cédula y carnet normalizados', () {
    final plan = planificarIdentificadores(alumnos: [ana], ocupados: const {});

    expect(plan.crear.map((item) => item.id), [
      'cedula_V-12345678',
      'carnet_20201111',
    ]);
    expect(plan.informe, isEmpty);
  });

  test('índices propios no generan escrituras', () {
    final plan = planificarIdentificadores(
      alumnos: [ana],
      ocupados: const {
        'cedula_V-12345678': 'ana',
        'carnet_20201111': 'ana',
      },
    );

    expect(plan.crear, isEmpty);
    expect(plan.informe, isEmpty);
  });

  test('duplicado con otro uid no escribe y el informe no muestra uids', () {
    final plan = planificarIdentificadores(
      alumnos: [ana, luis],
      ocupados: const {'cedula_V-12345678': 'ana'},
    );

    expect(plan.crear.map((item) => item.id), ['carnet_20201111', 'carnet_20202222']);
    expect(plan.crear.any((item) => item.id == 'cedula_V-12345678'), isFalse);
    final texto = plan.informe.join('\n');
    expect(texto, contains('Ana Pérez'));
    expect(texto, contains('Luis Gómez'));
    expect(texto, isNot(contains('ana')));
    expect(texto, isNot(contains('luis')));
    expect(texto, contains(AppStrings.adminSinIndiceIdentificador));
  });

  test('un duplicado no impide iniciar ni restaurar la sesión', () async {
    var escrituras = 0;
    final auth = AuthController(
      entrar: (correo, clave) async => 'ana',
      uidSesion: () => 'ana',
      leerRol: (uid) async => (
        error: false,
        existe: true,
        rol: 'estudiante',
        estado: 'activo',
      ),
      asegurarIdentificadores: (uid) async {
        final plan = planificarIdentificadores(
          alumnos: [ana],
          ocupados: const {'cedula_V-12345678': 'otro', 'carnet_20201111': 'otro'},
        );
        escrituras += plan.crear.length;
        throw StateError('índice ajeno');
      },
    );
    addTearDown(auth.dispose);

    final destino = await auth.iniciarSesion(
      'ana@correo.unimet.edu.ve',
      'Clave123',
    );
    final restaurada = await auth.rolSesionActual();

    expect(destino, DestinoLogin.estudiante);
    expect(restaurada.destino, DestinoLogin.estudiante);
    expect(auth.error, isNull);
    expect(escrituras, 0);
  });
}
