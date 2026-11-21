import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/repositories/notificaciones_repository.dart';

class NotificacionesController extends ChangeNotifier {
  NotificacionesController({NotificacionesRepository? repositorio})
    : _repositorio = repositorio ?? FirebaseNotificacionesAdapter();

  final NotificacionesRepository _repositorio;
  final List<Notificacion> _propias = [];
  final List<Notificacion> _bandeja = [];
  StreamSubscription<String?>? _sesion;
  StreamSubscription<List<Notificacion>>? _subPropias;
  StreamSubscription<List<Notificacion>>? _subBandeja;
  bool _cerrado = false;
  bool cargando = false;
  String? error;

  List<Notificacion> get notificaciones {
    final todas = [..._propias, ..._bandeja];
    todas.sort((a, b) => b.fecha.compareTo(a.fecha));
    return todas;
  }

  int get noLeidas => notificaciones.where((aviso) => !aviso.leida).length;

  void iniciar() {
    if (_sesion != null || _cerrado) return;
    try {
      _sesion = _repositorio.uidSesion().listen(_alCambiarSesion, onError: _fallo);
    } catch (e) {
      _fallo(e);
    }
  }

  Future<void> _alCambiarSesion(String? uid) async {
    await _subPropias?.cancel();
    await _subBandeja?.cancel();
    _subPropias = null;
    _subBandeja = null;
    _propias.clear();
    _bandeja.clear();
    if (uid == null) {
      cargando = false;
      error = null;
      _avisar();
      return;
    }
    cargando = true;
    error = null;
    _avisar();
    try {
      final rol = await _repositorio.rolDe(uid);
      if (_cerrado) return;
      _subPropias = _repositorio.propias(uid).listen((lista) {
        _propias
          ..clear()
          ..addAll(lista);
        cargando = false;
        error = null;
        _avisar();
      }, onError: _fallo);
      if (rol == 'administrador') {
        _subBandeja = _repositorio.bandejaAdmin().listen((lista) {
          _bandeja
            ..clear()
            ..addAll(lista);
          cargando = false;
          error = null;
          _avisar();
        }, onError: _fallo);
      }
    } catch (e) {
      _fallo(e);
    }
  }

  Future<String?> marcarLeida(Notificacion aviso) {
    return _repositorio.marcarLeida(aviso);
  }

  Future<String?> marcarTodas() async {
    String? primero;
    for (final aviso in notificaciones.where((item) => !item.leida)) {
      primero ??= await marcarLeida(aviso);
    }
    return primero;
  }

  Future<String?> responder(Notificacion aviso, bool asistira) {
    return _repositorio.responderParticipacion(aviso, asistira);
  }

  void _fallo(Object fallo) {
    cargando = false;
    error = '$fallo';
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _sesion?.cancel();
    _subPropias?.cancel();
    _subBandeja?.cancel();
    super.dispose();
  }
}
