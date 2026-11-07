import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/models/reserva_horario.dart';
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

class ProximaClaseEntrenador {
  const ProximaClaseEntrenador({
    required this.disciplina,
    this.inicio,
    this.franja,
  });

  final Deporte disciplina;
  final DateTime? inicio;
  final FranjaHorario? franja;
}

class InicioEntrenadorController extends ChangeNotifier {
  InicioEntrenadorController({
    EntrenadorRepository? entrenadorRepository,
    PerfilEntrenadorRepository? perfilRepository,
    HistorialAsistenciaRepository? historialRepository,
    DateTime Function()? reloj,
  }) : _entrenador = entrenadorRepository ?? FirebaseEntrenadorAdapter(),
       _perfil = perfilRepository ?? FirebasePerfilEntrenadorAdapter(),
       _historial = historialRepository ?? FirebaseHistorialAsistenciaAdapter(),
       _reloj = reloj ?? DateTime.now;

  final EntrenadorRepository _entrenador;
  final PerfilEntrenadorRepository _perfil;
  final HistorialAsistenciaRepository _historial;
  final DateTime Function() _reloj;

  PerfilEntrenador? perfil;
  List<Deporte> disciplinas = [];
  List<AsistenciaRecienteEntrenador> asistenciasRecientes = [];
  String? advertenciaAsistencias;
  bool cargando = false;
  String? error;
  bool _cerrado = false;

  int get totalEstudiantes =>
      disciplinas.fold(0, (total, disciplina) => total + disciplina.inscritos);

  ProximaClaseEntrenador? get proximaClase {
    final ahora = _reloj();
    ProximaClaseEntrenador? proxima;
    for (final disciplina in disciplinas) {
      for (final franja in disciplina.horarios) {
        final dias = (franja.dia - ahora.weekday + 7) % 7;
        var inicio = DateTime(
          ahora.year,
          ahora.month,
          ahora.day + dias,
          franja.horaInicio ~/ 60,
          franja.horaInicio % 60,
        );
        if (!inicio.isAfter(ahora)) {
          inicio = inicio.add(const Duration(days: 7));
        }
        if (proxima?.inicio == null || inicio.isBefore(proxima!.inicio!)) {
          proxima = ProximaClaseEntrenador(
            disciplina: disciplina,
            inicio: inicio,
            franja: franja,
          );
        }
      }
    }
    if (proxima != null) return proxima;
    for (final disciplina in disciplinas) {
      if (disciplina.horario.trim().isNotEmpty) {
        return ProximaClaseEntrenador(disciplina: disciplina);
      }
    }
    return disciplinas.isEmpty
        ? null
        : ProximaClaseEntrenador(disciplina: disciplinas.first);
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    advertenciaAsistencias = null;
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
    var fallos = 0;
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
          fallos++;
          return const <AsistenciaRecienteEntrenador>[];
        }
      }),
    );
    final todas = grupos.expand((grupo) => grupo).toList()
      ..sort((a, b) => b.sesion.fecha.compareTo(a.sesion.fecha));
    if (fallos > 0) {
      advertenciaAsistencias =
          'No se pudo cargar parte del historial de asistencia. Reintenta.';
    }
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
