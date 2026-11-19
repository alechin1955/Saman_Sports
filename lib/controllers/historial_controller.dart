import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/models/inscripcion.dart';

/// Sesiones de asistencia de una disciplina (deportes/{id}/asistencias).
typedef LeerAsistencias =
    Future<List<Map<String, dynamic>>> Function(String deporteId);

/// Clases registradas y a cuántas asistió el estudiante.
class ResumenAsistencia {
  const ResumenAsistencia({required this.presentes, required this.total});

  final int presentes;
  final int total;

  /// Porcentaje redondeado, o null si todavía no hay clases registradas.
  int? get porcentaje => total == 0 ? null : (presentes * 100 / total).round();

  /// Cuenta las sesiones donde aparece la inscripción. El entrenador guarda
  /// `estados` con la clave del id de la inscripción: 'presente' o 'ausente'.
  static ResumenAsistencia calcular(
    String inscripcionId,
    List<Map<String, dynamic>> sesiones,
  ) {
    var presentes = 0;
    var total = 0;
    for (final sesion in sesiones) {
      final estados = sesion['estados'];
      if (estados is! Map || !estados.containsKey(inscripcionId)) continue;
      total++;
      if (estados[inscripcionId] == 'presente') presentes++;
    }
    return ResumenAsistencia(presentes: presentes, total: total);
  }
}

/// Controlador del historial del estudiante (RF-14).
///
/// Observer encadenado: escucha a InscripcionesController y, por cada
/// inscripción nueva, lee la asistencia que registró el entrenador para
/// calcular el porcentaje del estudiante.
class HistorialController extends ChangeNotifier {
  HistorialController({
    required this.inscripciones,
    LeerAsistencias? leerAsistencias,
  }) : _leer =
           leerAsistencias ??
           ((deporteId) =>
               FirebaseServices.getAsistenciasDisciplina(deporteId: deporteId)) {
    inscripciones.addListener(_alCambiarInscripciones);
  }

  final InscripcionesController inscripciones;
  final LeerAsistencias _leer;

  final Map<String, ResumenAsistencia> _resumenes = {};
  final Set<String> _consultando = {};
  final Set<String> _sinDatos = {};
  bool _cerrado = false;

  bool get cargando => inscripciones.cargando;
  String? get error => inscripciones.error;

  /// Todas las inscripciones, también las canceladas, de la más nueva a la
  /// más vieja.
  List<Inscripcion> get historial => inscripciones.inscripciones;

  /// Vuelve a leer la asistencia de todas las inscripciones.
  void iniciar() {
    _resumenes.clear();
    _sinDatos.clear();
    inscripciones.iniciar();
    _alCambiarInscripciones();
  }

  void _alCambiarInscripciones() {
    for (final inscripcion in historial) {
      final id = inscripcion.id;
      if (_resumenes.containsKey(id) ||
          _consultando.contains(id) ||
          _sinDatos.contains(id)) {
        continue;
      }
      _cargar(inscripcion);
    }
    if (!_cerrado) notifyListeners();
  }

  Future<void> _cargar(Inscripcion inscripcion) async {
    _consultando.add(inscripcion.id);
    try {
      final sesiones = await _leer(
        inscripcion.deporteId,
      ).timeout(const Duration(seconds: 10));
      _resumenes[inscripcion.id] = ResumenAsistencia.calcular(
        inscripcion.id,
        sesiones,
      );
    } catch (_) {
      _sinDatos.add(inscripcion.id);
    } finally {
      _consultando.remove(inscripcion.id);
      if (!_cerrado) notifyListeners();
    }
  }

  /// Asistencia de una inscripción, o null si no se pudo leer.
  ResumenAsistencia? resumenDe(String inscripcionId) =>
      _resumenes[inscripcionId];

  bool consultando(String inscripcionId) =>
      _consultando.contains(inscripcionId);

  /// Suma de todas las disciplinas: asistencia general del estudiante.
  ResumenAsistencia get general {
    var presentes = 0;
    var total = 0;
    for (final resumen in _resumenes.values) {
      presentes += resumen.presentes;
      total += resumen.total;
    }
    return ResumenAsistencia(presentes: presentes, total: total);
  }

  @override
  void dispose() {
    _cerrado = true;
    inscripciones.removeListener(_alCambiarInscripciones);
    super.dispose();
  }
}