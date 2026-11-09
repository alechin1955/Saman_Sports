import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/repositories/entrenador/entrenador_notificacion_repository.dart';

class EntrenadorNotificacionController extends ChangeNotifier {
  EntrenadorNotificacionController({
    EntrenadorNotificacionRepository? repository,
  }) : _repository = repository ?? FirebaseEntrenadorNotificacionAdapter();

  static const String titulo = 'Notificaciones';
  static const String vacio = 'No tienes notificaciones.';
  static const String marcar = 'Marcar leída';
  static const String cerrar = 'Cerrar';

  final EntrenadorNotificacionRepository _repository;
  List<Notificacion> notificaciones = [];
  bool cargando = false;
  String? error;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Notificacion>>? _sub;

  int get noLeidas => notificaciones.where((aviso) => !aviso.leida).length;

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.notificaciones().listen((lista) {
      if (_cerrado) return;
      notificaciones = [...lista]..sort((a, b) => b.fecha.compareTo(a.fecha));
      cargando = false;
      error = null;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar las notificaciones.'));
  }

  Future<String?> marcarLeida(Notificacion aviso) async {
    if (_cerrado || aviso.leida) return null;
    final resultado = await _repository.marcarLeida(aviso.id);
    if (_cerrado) return resultado;
    if (resultado != null) {
      error = resultado;
      _avisar();
    }
    return resultado;
  }

  void _fallo(String texto) {
    if (_cerrado) return;
    cargando = false;
    error = texto;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _sub?.cancel();
    super.dispose();
  }
}
