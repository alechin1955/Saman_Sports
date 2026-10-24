import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/estudiante.dart';

const _datos = <String, dynamic>{
  'nombre': 'María',
  'apellido': 'González',
  'cedula': 'V-28123456',
  'carnet': '20231110123',
  'telefono': '0414-1234567',
  'correo': 'maria@correo.unimet.edu.ve',
  'rol': 'estudiante',
};

void main() {
  group('Estudiante (modelo)', () {
    test('fromMap lee los datos y usa valores por defecto', () {
      final e = Estudiante.fromMap('abc', _datos);

      expect(e.uid, 'abc');
      expect(e.nombreCompleto, 'María González');
      expect(e.iniciales, 'MG');
      expect(e.carnet, '20231110123');
      expect(e.activo, isTrue);
      expect(e.solvente, isFalse);
    });

    test('un estudiante inactivo se lee como inactivo', () {
      final e = Estudiante.fromMap('abc', {..._datos, 'estado': 'inactivo'});
      expect(e.activo, isFalse);
    });

    test('toMapEditable solo incluye nombre, apellido y teléfono', () {
      final mapa = Estudiante.fromMap('abc', _datos).toMapEditable();
      expect(mapa.keys, unorderedEquals(['nombre', 'apellido', 'telefono']));
    });
  });

  group('EstudianteController', () {
    test('carga el perfil del estudiante con sesión abierta', () async {
      final c = EstudianteController(
        uidActual: () => 'abc',
        leer: (uid) async => _datos,
      );

      await c.cargarPerfil();

      expect(c.cargando, isFalse);
      expect(c.error, isNull);
      expect(c.estudiante?.nombre, 'María');
      c.dispose();
    });

    test('sin sesión muestra el mensaje de sesión expirada', () async {
      final c = EstudianteController(uidActual: () => null);

      await c.cargarPerfil();

      expect(c.estudiante, isNull);
      expect(c.error, AppStrings.sesionNoIniciada);
      c.dispose();
    });

    test('si no existe el documento muestra perfil no encontrado', () async {
      final c = EstudianteController(
        uidActual: () => 'abc',
        leer: (uid) async => null,
      );

      await c.cargarPerfil();

      expect(c.error, AppStrings.perfilNoEncontrado);
      c.dispose();
    });

    test('un teléfono inválido no se guarda', () async {
      var guardo = false;
      final c = EstudianteController(
        uidActual: () => 'abc',
        leer: (uid) async => _datos,
        guardar: (uid, datos) async {
          guardo = true;
          return AuthResponse(isSuccess: true);
        },
      );
      await c.cargarPerfil();

      final ok = await c.actualizarPerfil(
        nombre: 'María',
        apellido: 'González',
        telefono: '123',
      );

      expect(ok, isFalse);
      expect(guardo, isFalse);
      expect(c.error, AppStrings.telefonoInvalido);
      c.dispose();
    });

    test('guarda los cambios y actualiza el estudiante', () async {
      Map<String, dynamic>? guardado;
      final c = EstudianteController(
        uidActual: () => 'abc',
        leer: (uid) async => _datos,
        guardar: (uid, datos) async {
          guardado = datos;
          return AuthResponse(isSuccess: true);
        },
      );
      await c.cargarPerfil();

      final ok = await c.actualizarPerfil(
        nombre: 'Ana',
        apellido: 'Pérez',
        telefono: '0424-7654321',
      );

      expect(ok, isTrue);
      expect(c.guardando, isFalse);
      expect(c.estudiante?.nombreCompleto, 'Ana Pérez');
      expect(guardado, {
        'nombre': 'Ana',
        'apellido': 'Pérez',
        'telefono': '0424-7654321',
      });
      c.dispose();
    });

    test('si Firebase falla muestra el mensaje de la fachada', () async {
      final c = EstudianteController(
        uidActual: () => 'abc',
        leer: (uid) async => _datos,
        guardar: (uid, datos) async => AuthResponse(
          isSuccess: false,
          errorMessage: 'No tienes permiso para realizar esta acción.',
        ),
      );
      await c.cargarPerfil();

      final ok = await c.actualizarPerfil(
        nombre: 'Ana',
        apellido: 'Pérez',
        telefono: '0424-7654321',
      );

      expect(ok, isFalse);
      expect(c.error, 'No tienes permiso para realizar esta acción.');
      expect(c.estudiante?.nombre, 'María');
      c.dispose();
    });
  });
}
