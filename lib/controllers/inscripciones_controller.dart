import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/inscripcion.dart';

/// Inscripciones de un estudiante, en vivo.
typedef OrigenInscripciones =
    Stream<List<Map<String, dynamic>>> Function(String uid);

/// Inscribir o cancelar: recibe el id del deporte o de la inscripción.
typedef AccionInscripcion = Future<AuthResponse> Function(String id);

/// Lee si el estudiante con sesión abierta tiene `solvente == true`.
typedef LeerSolvencia = Future<bool> Function();

/// Controlador de las inscripciones del estudiante (RF-04 y RF-05).
///
/// Observer: escucha la colección inscripciones del estudiante y avisa a
/// Explorar, Mis disciplinas y el detalle de cada deporte. Solo habla con
/// Firebase a través de la fachada; las funciones se pueden inyectar para
/// probarlo sin Firebase.
class InscripcionesController extends ChangeNotifier {
  InscripcionesController({
    String? Function()? uidActual,
    OrigenInscripciones? origen,
    AccionInscripcion? inscribir,
    AccionInscripcion? cancelar,
    this._leerSolvencia,
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _origen =
           origen ??
           ((uid) =>
               FirebaseServices.streamMisInscripciones(estudianteUid: uid)),
       _inscribir =
           inscribir ??
           ((id) => FirebaseServices.inscribirseEnDeporte(deporteId: id)),
       _cancelar =
           cancelar ??
           ((id) => FirebaseServices.cancelarInscripcion(inscripcionId: id)) {
    if (_leerSolvencia != null) {
      solvente = false;
      solvenciaConocida = false;
    }
  }

  final String? Function() _uidActual;
  final OrigenInscripciones _origen;
  final AccionInscripcion _inscribir;
  final AccionInscripcion _cancelar;
  final LeerSolvencia? _leerSolvencia;

  List<Inscripcion> inscripciones = [];
  bool cargando = true;
  bool procesando = false;
  String? error;

  /// True si el estudiante puede inscribirse. Sin lector queda en true
  /// para no bloquear las pruebas que no hablan de solvencia.
  bool solvente = true;

  /// False mientras el lector inyectado no ha respondido.
  bool solvenciaConocida = true;
  bool _cerrado = false;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _uidEscuchado;

  /// Se suscribe a las inscripciones del estudiante con sesión abierta.
  /// Si ya escucha al mismo estudiante no vuelve a suscribirse.
  void iniciar() {
    final uid = _uidActual();
    if (uid == null) {
      _sub?.cancel();
      _uidEscuchado = null;
      inscripciones = [];
      cargando = false;
      error = AppStrings.sesionNoIniciada;
      _avisar();
      return;
    }
    if (uid == _uidEscuchado && _sub != null) return;

    _sub?.cancel();
    _uidEscuchado = uid;
    cargando = true;
    error = null;
    _avisar();
    unawaited(_asegurarSolvencia());
    try {
      _sub = _origen(uid).listen(_recibir, onError: (_) => _fallar());
    } catch (_) {
      _fallar();
    }
  }

  /// Consulta `solvente` una sola vez. Si el lector falla, no deja inscribir.
  Future<void> _asegurarSolvencia() async {
    final leer = _leerSolvencia;
    if (leer == null || solvenciaConocida || _cerrado) return;
    try {
      final valor = await leer();
      if (_cerrado) return;
      solvente = valor;
    } catch (_) {
      if (_cerrado) return;
      solvente = false;
    }
    solvenciaConocida = true;
    _avisar();
  }

  void _recibir(List<Map<String, dynamic>> lista) {
    inscripciones = lista.map(Inscripcion.fromMap).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    cargando = false;
    error = null;
    _avisar();
  }

  void _fallar() {
    cargando = false;
    error = AppStrings.errorConexion;
    _avisar();
  }

  /// Inscripciones que ocupan cupo (pendientes o confirmadas).
  List<Inscripcion> get activas =>
      inscripciones.where((i) => i.activa).toList();

  /// Inscripción activa del estudiante en ese deporte, o null.
  Inscripcion? activaEn(String deporteId) {
    for (final inscripcion in activas) {
      if (inscripcion.deporteId == deporteId) return inscripcion;
    }
    return null;
  }

  /// Se puede inscribir si está solvente, no está inscrito y quedan cupos.
  bool puedeInscribirse(Deporte deporte) =>
      solvente && activaEn(deporte.id) == null && deporte.disponibles > 0;

  /// Inscribe al estudiante. Devuelve null si salió bien o el mensaje de error.
  Future<String?> inscribirse(Deporte deporte) async {
    await _asegurarSolvencia();
    if (!solvente) {
      error = AppStrings.debesEstarSolvente;
      _avisar();
      return error;
    }
    if (activaEn(deporte.id) != null) return AppStrings.inscripcionYaExiste;
    if (deporte.disponibles <= 0) return AppStrings.inscripcionSinCupos;
    return _ejecutar(() => _inscribir(deporte.id));
  }

  /// Cancela la inscripción y libera el cupo. Devuelve null si salió bien.
  Future<String?> cancelar(Inscripcion inscripcion) {
    return _ejecutar(() => _cancelar(inscripcion.id));
  }

  Future<String?> _ejecutar(Future<AuthResponse> Function() accion) async {
    if (procesando) return AppStrings.esperaUnMomento;
    procesando = true;
    _avisar();
    try {
      final respuesta = await accion().timeout(const Duration(seconds: 15));
      if (respuesta.isSuccess) return null;
      return respuesta.errorMessage ?? AppStrings.errorInesperado;
    } on TimeoutException {
      return AppStrings.errorConexion;
    } catch (_) {
      return AppStrings.errorInesperado;
    } finally {
      procesando = false;
      _avisar();
    }
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