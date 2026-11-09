import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/notificacion.dart';

/// Avisos de un estudiante, en vivo.
typedef OrigenNotificaciones =
    Stream<List<Map<String, dynamic>>> Function(String uid);

/// Marca un aviso como leído.
typedef MarcarLeida = Future<AuthResponse> Function(String id);

/// Controlador de "Recordatorios" del estudiante.
///
/// Observer: escucha la colección notificaciones (los avisos que crea el
/// administrador: pago pendiente y eventos) y permite marcarlos como leídos.
class RecordatoriosController extends ChangeNotifier {
  RecordatoriosController({
    String? Function()? uidActual,
    OrigenNotificaciones? origen,
    MarcarLeida? marcar,
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _origen =
           origen ??
           ((uid) => FirebaseServices.streamMisNotificaciones(uid: uid)),
       _marcar =
           marcar ??
           ((id) => FirebaseServices.marcarNotificacionLeida(id: id));

  final String? Function() _uidActual;
  final OrigenNotificaciones _origen;
  final MarcarLeida _marcar;

  List<Notificacion> avisos = [];
  bool cargando = true;
  bool procesando = false;
  String? error;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _uidEscuchado;

  int get noLeidos => avisos.where((aviso) => !aviso.leida).length;

  /// Se suscribe a los avisos del estudiante con sesión abierta.
  void iniciar() {
    final uid = _uidActual();
    if (uid == null) {
      _sub?.cancel();
      _sub = null;
      _uidEscuchado = null;
      avisos = [];
      cargando = false;
      error = AppStrings.sesionNoIniciada;
      notifyListeners();
      return;
    }
    if (uid == _uidEscuchado && _sub != null) return;

    _sub?.cancel();
    _uidEscuchado = uid;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      _sub = _origen(uid).listen(_recibir, onError: (_) => _fallar());
    } catch (_) {
      _fallar();
    }
  }

  void _recibir(List<Map<String, dynamic>> lista) {
    avisos = lista
        .map((mapa) => Notificacion.fromMap('${mapa['id'] ?? ''}', mapa))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    cargando = false;
    error = null;
    notifyListeners();
  }

  void _fallar() {
    cargando = false;
    error = AppStrings.errorConexion;
    notifyListeners();
  }

  /// Marca un aviso como leído. Devuelve null si salió bien.
  Future<String?> marcarLeido(Notificacion aviso) async {
    if (aviso.leida) return null;
    final respuesta = await _marcar(aviso.id);
    if (respuesta.isSuccess) return null;
    return respuesta.errorMessage ?? AppStrings.errorInesperado;
  }

  /// Marca como leídos todos los avisos pendientes. Devuelve el primer error.
  Future<String?> marcarTodos() async {
    if (procesando) return AppStrings.esperaUnMomento;
    procesando = true;
    notifyListeners();
    String? primerError;
    try {
      for (final aviso in avisos.where((a) => !a.leida).toList()) {
        primerError ??= await marcarLeido(aviso);
      }
      return primerError;
    } finally {
      procesando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}