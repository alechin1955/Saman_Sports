import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/historial_asistencia_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';

class AsistenciaRecienteEntrenador {
  const AsistenciaRecienteEntrenador({
    required this.disciplina,
    required this.sesion,
  });

  final Deporte disciplina;
  final SesionAsistencia sesion;

  int get presentes => sesion.estados.values
      .where((estado) => estado == EstadoAsistencia.presente)
      .length;
  int get ausentes => sesion.estados.values
      .where((estado) => estado == EstadoAsistencia.ausente)
      .length;
}

class InicioEntrenadorController extends ChangeNotifier {
  InicioEntrenadorController({
    EntrenadorRepository? entrenadorRepository,
    PerfilEntrenadorRepository? perfilRepository,
    HistorialAsistenciaRepository? historialRepository,
  }) : _entrenador = entrenadorRepository ?? FirebaseEntrenadorAdapter(),
       _perfil = perfilRepository ?? FirebasePerfilEntrenadorAdapter(),
       _historial = historialRepository ?? FirebaseHistorialAsistenciaAdapter();

  final EntrenadorRepository _entrenador;
  final PerfilEntrenadorRepository _perfil;
  final HistorialAsistenciaRepository _historial;

  PerfilEntrenador? perfil;
  List<Deporte> disciplinas = [];
  List<AsistenciaRecienteEntrenador> asistenciasRecientes = [];
  bool cargando = false;
  String? error;
  bool _cerrado = false;

  int get totalEstudiantes =>
      disciplinas.fold(0, (total, disciplina) => total + disciplina.inscritos);

  Deporte? get proximaClase {
    for (final disciplina in disciplinas) {
      if (disciplina.horario.trim().isNotEmpty) return disciplina;
    }
    return disciplinas.isEmpty ? null : disciplinas.first;
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    _avisar();
    try {
      final resultados = await Future.wait<Object>([
        _perfil.cargar(),
        _entrenador.disciplinas(),
      ]).timeout(const Duration(seconds: 15));
      if (_cerrado) return;
      perfil = resultados[0] as PerfilEntrenador;
      disciplinas = resultados[1] as List<Deporte>;
      asistenciasRecientes = await _cargarAsistencias(disciplinas);
    } catch (_) {
      if (!_cerrado) {
        error = 'No se pudo cargar tu resumen. Revisa la conexión y reintenta.';
      }
    } finally {
      if (!_cerrado) {
        cargando = false;
        _avisar();
      }
    }
  }

  Future<List<AsistenciaRecienteEntrenador>> _cargarAsistencias(
    List<Deporte> lista,
  ) async {
    final grupos = await Future.wait(
      lista.map((disciplina) async {
        try {
          final sesiones = await _historial.sesiones(disciplina.id);
          return sesiones.map(
            (sesion) => AsistenciaRecienteEntrenador(
              disciplina: disciplina,
              sesion: sesion,
            ),
          );
        } catch (_) {
          return const <AsistenciaRecienteEntrenador>[];
        }
      }),
    );
    final todas = grupos.expand((grupo) => grupo).toList()
      ..sort((a, b) => b.sesion.fecha.compareTo(a.sesion.fecha));
    return todas.take(5).toList(growable: false);
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
