import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/ticket_soporte_estudiante.dart';
import 'package:saman_sports/models/ticket_soporte.dart';

/// Tickets de un estudiante, en vivo.
typedef OrigenTickets = Stream<List<Map<String, dynamic>>> Function(String uid);

/// Crea un ticket con categoría, asunto y descripción.
typedef CrearTicket =
    Future<AuthResponse> Function(
      String categoria,
      String asunto,
      String descripcion,
    );

/// Controlador de "Soporte" del estudiante.
///
/// Observer: escucha los tickets del estudiante, así ve en tiempo real
/// cuando el administrador responde o marca uno como resuelto.
class SoporteEstudianteController extends ChangeNotifier {
  SoporteEstudianteController({
    String? Function()? uidActual,
    OrigenTickets? origen,
    CrearTicket? crear,
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _origen =
           origen ?? ((uid) => FirebaseServices.streamMisTickets(uid: uid)),
       _crear =
           crear ??
           ((categoria, asunto, descripcion) =>
               FirebaseServices.crearTicketEstudiante(
                 categoria: categoria,
                 asunto: asunto,
                 descripcion: descripcion,
               ));

  final String? Function() _uidActual;
  final OrigenTickets _origen;
  final CrearTicket _crear;

  List<TicketSoporte> tickets = [];
  bool cargando = true;
  bool enviando = false;
  String? error;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _uidEscuchado;

  /// Se suscribe a los tickets del estudiante con sesión abierta.
  void iniciar() {
    final uid = _uidActual();
    if (uid == null) {
      _sub?.cancel();
      _sub = null;
      _uidEscuchado = null;
      tickets = [];
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
    tickets = lista
        .map((mapa) => TicketSoporte.fromMap('${mapa['id'] ?? ''}', mapa))
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

  /// Valida y envía el ticket. Devuelve null si salió bien o el mensaje.
  Future<String?> enviar({
    required String categoria,
    required String asunto,
    required String descripcion,
  }) async {
    if (enviando) return AppStrings.esperaUnMomento;
    final invalido = validarTicketEstudiante(
      categoria: categoria,
      asunto: asunto,
      descripcion: descripcion,
    );
    if (invalido != null) return invalido;

    enviando = true;
    notifyListeners();
    try {
      final respuesta = await _crear(
        categoria,
        asunto.trim(),
        descripcion.trim(),
      ).timeout(const Duration(seconds: 15));
      if (respuesta.isSuccess) return null;
      return respuesta.errorMessage ?? AppStrings.errorInesperado;
    } on TimeoutException {
      return AppStrings.errorConexion;
    } catch (_) {
      return AppStrings.errorInesperado;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}