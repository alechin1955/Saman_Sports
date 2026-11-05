import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/repositories/admin/admin_soporte_repository.dart';

class AdminSoporteController extends ChangeNotifier {
  AdminSoporteController({AdminSoporteRepository? repository})
    : _repository = repository ?? FirebaseAdminSoporteAdapter();

  static const String respuestaObligatoria =
      'La respuesta debe tener al menos 5 caracteres.';

  final AdminSoporteRepository _repository;
  List<TicketSoporte> tickets = [];
  EstadoTicket? filtro;
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<TicketSoporte>>? _sub;

  List<TicketSoporte> get ticketsFiltrados {
    if (filtro == null) return tickets;
    return tickets.where((ticket) => ticket.estado == filtro).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.tickets().listen((lista) {
      tickets = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar los tickets.'));
  }

  void cambiarFiltro(EstadoTicket? valor) {
    filtro = valor;
    _avisar();
  }

  Future<String?> responder(TicketSoporte ticket, String respuesta) {
    return _guardar(() async {
      if (respuesta.trim().length < 5) return respuestaObligatoria;
      return _repository.responder(id: ticket.id, respuesta: respuesta.trim());
    }, 'Ticket respondido.');
  }

  Future<String?> _guardar(
    Future<String?> Function() accion,
    String exito,
  ) async {
    if (_cerrado) return 'La operación ya no está disponible.';
    guardando = true;
    error = null;
    _avisar();
    try {
      final resultado = await accion();
      if (_cerrado) return resultado;
      if (resultado == null) {
        mensaje = exito;
      } else {
        error = resultado;
      }
      return resultado;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
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
