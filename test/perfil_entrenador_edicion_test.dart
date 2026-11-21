import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/perfil_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';

void main() {
  test('valida años, guarda y recarga', () async {
    final edicion = _Edicion();
    final lectura = _Lectura();
    final controller = PerfilEntrenadorController(
      repository: lectura,
      entrenadorRepository: _Nomina(),
      edicion: edicion,
    );
    addTearDown(controller.dispose);
    await controller.cargar();

    expect(
      await controller.guardarPerfil(
        telefono: '04120000000',
        biografia: 'Nueva',
        anosExperiencia: 80,
        certificaciones: const [],
      ),
      isFalse,
    );
    expect(controller.error, AppStrings.entAnosInvalidos);

    final ok = await controller.guardarPerfil(
      telefono: '04120000000',
      biografia: 'Nueva',
      anosExperiencia: 4,
      certificaciones: const ['FIVB'],
    );

    expect(ok, isTrue);
    expect(edicion.telefono, '04120000000');
    expect(edicion.anos, 4);
    expect(lectura.cargas, 2);
  });
}

class _Lectura implements PerfilEntrenadorRepository {
  int cargas = 0;

  @override
  Future<PerfilEntrenador> cargar() async {
    cargas++;
    return const PerfilEntrenador(
      uid: 'e1',
      nombre: 'Ana',
      apellido: 'Ruiz',
      correo: 'ana@unimet.edu.ve',
      telefono: '04121111111',
      disciplina: 'Tenis',
      especialidad: 'Campo',
      biografia: 'Antes',
      anosExperiencia: 2,
      certificaciones: [],
      activo: true,
    );
  }
}

class _Edicion implements PerfilEntrenadorEdicionRepository {
  String? telefono;
  int? anos;

  @override
  Future<String?> guardar({
    required String uid,
    required String telefono,
    required String biografia,
    required int anosExperiencia,
    required List<String> certificaciones,
  }) async {
    this.telefono = telefono;
    anos = anosExperiencia;
    if (telefono.length < 8) return AppStrings.telefonoInvalido;
    return null;
  }
}

class _Nomina implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [];

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => const [];
}
