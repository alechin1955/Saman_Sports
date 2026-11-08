import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';

class PerfilEntrenadorController extends ChangeNotifier {
  PerfilEntrenadorController({
    PerfilEntrenadorRepository? repository,
    EntrenadorRepository? entrenadorRepository,
  }) : _repository = repository ?? FirebasePerfilEntrenadorAdapter(),
       _entrenador = entrenadorRepository ?? FirebaseEntrenadorAdapter();

  final PerfilEntrenadorRepository _repository;
  final EntrenadorRepository _entrenador;
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
      if (!_cerrado) error = 'No se pudo cargar tu perfil. Vuelve a intentar.';
    } finally {
      if (!_cerrado) {
        cargando = false;
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
