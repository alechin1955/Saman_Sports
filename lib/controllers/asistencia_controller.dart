import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';

class AsistenciaController extends ChangeNotifier {
  AsistenciaController({AsistenciaRepository? repository})
    : _repository = repository ?? FirestoreAsistenciaRepository();
  final AsistenciaRepository _repository;
  String? deporteId;
  DateTime fecha = DateTime.now();
  List<AlumnoInscrito> alumnos = [];
  Map<String, EstadoAsistencia> estados = {};
  Map<String, EstadoAsistencia> _guardados = {};
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  int _consulta = 0;

  bool get cambios => !mapEquals(estados, _guardados);
  bool get completa =>
      alumnos.isNotEmpty &&
      alumnos.every((a) => estados.containsKey(a.inscripcionId));
  int get presentes => alumnos
      .where((a) => estados[a.inscripcionId] == EstadoAsistencia.presente)
      .length;
  int get ausentes => alumnos
      .where((a) => estados[a.inscripcionId] == EstadoAsistencia.ausente)
      .length;

  Future<bool> abrir(
    String id,
    DateTime dia,
    List<AlumnoInscrito> nomina, {
    bool descartar = false,
  }) async {
    if (guardando || (cambios && !descartar)) return false;
    final hoy = DateTime.now();
    final normalizada = DateTime(dia.year, dia.month, dia.day);
    if (normalizada.isAfter(DateTime(hoy.year, hoy.month, hoy.day))) {
      return false;
    }
    final consulta = ++_consulta;
    deporteId = id;
    fecha = normalizada;
    alumnos = List.unmodifiable(nomina);
    estados = {};
    _guardados = {};
    cargando = true;
    error = null;
    mensaje = null;
    _avisar();
    try {
      final registros = await _repository
          .leer(id, fecha)
          .timeout(const Duration(seconds: 15));
      if (_cerrado || consulta != _consulta) return false;
      final ids = alumnos.map((a) => a.inscripcionId).toSet();
      estados = Map.fromEntries(
        registros.entries.where((e) => ids.contains(e.key)),
      );
      _guardados = Map.of(estados);
      return true;
    } catch (_) {
      if (!_cerrado && consulta == _consulta) {
        error =
            'No se pudo cargar la asistencia. Reintenta antes de registrar.';
      }
      return false;
    } finally {
      if (!_cerrado && consulta == _consulta) {
        cargando = false;
        _avisar();
      }
    }
  }

  void marcar(String inscripcionId, EstadoAsistencia estado) {
    if (cargando ||
        guardando ||
        error != null ||
        !alumnos.any((a) => a.inscripcionId == inscripcionId)) {
      return;
    }
    estados = {...estados, inscripcionId: estado};
    mensaje = null;
    _avisar();
  }

  Future<bool> guardar() async {
    if (cargando || guardando || !completa || !cambios || deporteId == null) {
      return false;
    }
    guardando = true;
    mensaje = null;
    _avisar();
    try {
      await _repository.guardar(deporteId!, fecha, Map.of(estados));
      if (_cerrado) return false;
      _guardados = Map.of(estados);
      mensaje = 'Asistencia guardada correctamente.';
      return true;
    } catch (_) {
      if (!_cerrado) {
        mensaje =
            'No se pudo guardar. Tus cambios siguen aquí; intenta nuevamente.';
      }
      return false;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
  }

  void descartarBorrador() {
    if (guardando) return;
    estados = Map.of(_guardados);
    mensaje = null;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _consulta++;
    super.dispose();
  }
}
