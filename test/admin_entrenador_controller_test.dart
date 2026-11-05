import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/repositories/admin/admin_entrenador_repository.dart';

void main() {
  late _FalsoEntrenadores repo;
  late AdminEntrenadorController controller;

  setUp(() {
    repo = _FalsoEntrenadores();
    controller = AdminEntrenadorController(repository: repo);
  });

  tearDown(() => controller.dispose());

  test('combina el perfil público con los datos privados', () async {
    repo.publicos = {
      'u1': {
        'id': 'u1',
        'nombre': 'Carlos',
        'apellido': 'Méndez',
        'disciplina': 'Fútbol',
        'descripcion': 'Campus',
        'activo': true,
        'especialidad': 'Juvenil',
        'anosExperiencia': 8,
      },
    };
    repo.privados = {
      'u1': {
        'id': 'u1',
        'cedula': 'V-12345678',
        'correo': 'carlos@unimet.edu.ve',
        'telefono': '04141234567',
      },
    };
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    expect(controller.entrenadores, hasLength(1));
    expect(controller.entrenadores.first.disciplina, 'Fútbol');
    expect(controller.entrenadores.first.cedula, 'V-12345678');
    expect(controller.entrenadores.first.correo, 'carlos@unimet.edu.ve');
  });

  test('rechaza correo externo, claves distintas y años negativos', () async {
    expect(
      await controller.crearEntrenador(
        nombre: 'Ana',
        apellido: 'Pérez',
        cedula: 'V-12345678',
        correo: 'ana@gmail.com',
        clave: 'secreta',
        confirmarClave: 'secreta',
        telefono: '04141234567',
        disciplina: 'Tenis',
        especialidad: 'Base',
        anosExperiencia: 2,
        descripcion: 'Clases',
      ),
      isNotNull,
    );
    expect(
      await controller.crearEntrenador(
        nombre: 'Ana',
        apellido: 'Pérez',
        cedula: 'V-12345678',
        correo: 'ana@unimet.edu.ve',
        clave: 'secreta',
        confirmarClave: 'otra',
        telefono: '04141234567',
        disciplina: 'Tenis',
        especialidad: 'Base',
        anosExperiencia: 2,
        descripcion: 'Clases',
      ),
      AdminEntrenadorController.clavesDistintas,
    );
    expect(
      await controller.crearEntrenador(
        nombre: 'Ana',
        apellido: 'Pérez',
        cedula: 'V-12345678',
        correo: 'ana@unimet.edu.ve',
        clave: 'secreta',
        confirmarClave: 'secreta',
        telefono: '04141234567',
        disciplina: 'Tenis',
        especialidad: 'Base',
        anosExperiencia: -1,
        descripcion: 'Clases',
      ),
      AdminEntrenadorController.experienciaInvalida,
    );
    expect(repo.cuentas, 0);
  });

  test('desactivar llama al repositorio con activo falso', () async {
    const entrenador = EntrenadorAdmin(
      uid: 'u1',
      nombre: 'Ana',
      apellido: 'Pérez',
      disciplina: 'Tenis',
      descripcion: '',
      activo: true,
      especialidad: 'Base',
      anosExperiencia: 2,
      correo: 'ana@unimet.edu.ve',
      cedula: 'V-1',
      telefono: '04141234567',
    );

    final resultado = await controller.cambiarEstado(entrenador, false);

    expect(resultado, isNull);
    expect(repo.ultimoActivo, isFalse);
    expect(repo.ultimoUid, 'u1');
  });
}

class _FalsoEntrenadores implements AdminEntrenadorRepository {
  Map<String, Map<String, dynamic>> publicos = {};
  Map<String, Map<String, dynamic>> privados = {};
  int cuentas = 0;
  bool? ultimoActivo;
  String? ultimoUid;

  @override
  Stream<Map<String, Map<String, dynamic>>> entrenadoresPublicos() {
    return Stream.value(publicos);
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> perfilesPrivados() {
    return Stream.value(privados);
  }

  @override
  Future<String?> crearCuenta({
    required String correo,
    required String clave,
    required EntrenadorAdmin datos,
  }) async {
    cuentas++;
    return null;
  }

  @override
  Future<String?> actualizar(EntrenadorAdmin datos) async => null;

  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async {
    ultimoUid = uid;
    ultimoActivo = activo;
    return null;
  }
}
