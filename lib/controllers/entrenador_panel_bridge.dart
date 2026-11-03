import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';

/// Puente entre la vista del panel y sus implementaciones de nómina/asistencia.
///
/// La vista solo orquesta navegación y diálogos. Este objeto conserva la regla
/// de sincronización entre ambos controladores, que pueden sustituirse de forma
/// independiente en pruebas o al cambiar la fuente de datos.
class EntrenadorPanelBridge extends ChangeNotifier {
  EntrenadorPanelBridge({
    EntrenadorController? entrenador,
    AsistenciaController? asistencia,
  }) : entrenador = entrenador ?? EntrenadorController(),
       asistencia = asistencia ?? AsistenciaController(),
       _disponeEntrenador = entrenador == null,
       _disponeAsistencia = asistencia == null {
    this.entrenador.addListener(_alCambiarEntrenador);
    this.asistencia.addListener(_avisar);
  }

  final EntrenadorController entrenador;
  final AsistenciaController asistencia;
  final bool _disponeEntrenador;
  final bool _disponeAsistencia;

  String? _seleccionCargada;
  Object? _nominaCargada;
  bool _cerrado = false;

  bool get bloqueaSalida => asistencia.cambios || asistencia.guardando;

  Future<void> cargar() => entrenador.cargar();

  void descartarBorrador() => asistencia.descartarBorrador();

  void _alCambiarEntrenador() {
    _sincronizarAsistencia();
    _avisar();
  }

  void _sincronizarAsistencia() {
    if (_cerrado ||
        entrenador.cargando ||
        entrenador.cargandoNomina ||
        entrenador.error != null) {
      return;
    }

    final id = entrenador.seleccionId;
    final cambioSeleccion = id != null && id != _seleccionCargada;
    final cambioNomina = !identical(_nominaCargada, entrenador.alumnos);
    if (id == null ||
        (!cambioSeleccion && !cambioNomina) ||
        asistencia.cambios ||
        asistencia.guardando) {
      return;
    }

    _seleccionCargada = id;
    _nominaCargada = entrenador.alumnos;
    unawaited(asistencia.abrir(id, asistencia.fecha, entrenador.alumnos));
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    entrenador.removeListener(_alCambiarEntrenador);
    asistencia.removeListener(_avisar);
    if (_disponeEntrenador) entrenador.dispose();
    if (_disponeAsistencia) asistencia.dispose();
    super.dispose();
  }
}
