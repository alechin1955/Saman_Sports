import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';

class PerfilEntrenadorController extends ChangeNotifier {
  PerfilEntrenadorController({
    PerfilEntrenadorRepository? repository,
    EntrenadorRepository? entrenadorRepository,
    PerfilEntrenadorEdicionRepository? edicion,
  }) : _repository = repository ?? FirebasePerfilEntrenadorAdapter(),
       _entrenador = entrenadorRepository ?? FirebaseEntrenadorAdapter(),
       _edicion = edicion ?? FirebasePerfilEntrenadorEdicionAdapter();

  final PerfilEntrenadorRepository _repository;
  final EntrenadorRepository _entrenador;
  final PerfilEntrenadorEdicionRepository _edicion;
  bool guardando = false;
  PerfilEntrenador? perfil;
  List<Deporte> disciplinas = [];
  bool cargando = false;
  String? error;
  bool _cerrado = false;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    _avisar();
    try {
      final resultados = await Future.wait<Object>([
        _repository.cargar(),
        _entrenador.disciplinas(),
      ]).timeout(const Duration(seconds: 15));
      perfil = resultados[0] as PerfilEntrenador;
      disciplinas = resultados[1] as List<Deporte>;
    } catch (_) {
      if (!_cerrado) error = AppStrings.entPerfilCarga;
    } finally {
      if (!_cerrado) {
        cargando = false;
        _avisar();
      }
    }
  }

  Future<bool> guardarPerfil({
    required String telefono,
    required String biografia,
    required int anosExperiencia,
    required List<String> certificaciones,
  }) async {
    final actual = perfil;
    if (actual == null) return false;
    if (anosExperiencia < 0 || anosExperiencia > 60) {
      error = AppStrings.entAnosInvalidos;
      _avisar();
      return false;
    }
    guardando = true;
    error = null;
    _avisar();
    try {
      final resultado = await _edicion.guardar(
        uid: actual.uid,
        telefono: telefono,
        biografia: biografia,
        anosExperiencia: anosExperiencia,
        certificaciones: certificaciones,
      );
      if (_cerrado) return false;
      if (resultado != null) {
        error = resultado;
        return false;
      }
      await cargar();
      return error == null;
    } catch (_) {
      if (!_cerrado) error = AppStrings.errorInesperado;
      return false;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
  }

  int get totalEstudiantes =>
      disciplinas.fold(0, (total, disciplina) => total + disciplina.inscritos);

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
