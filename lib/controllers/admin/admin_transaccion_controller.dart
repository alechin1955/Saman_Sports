import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/repositories/admin/admin_transaccion_repository.dart';

class AdminTransaccionController extends ChangeNotifier {
  AdminTransaccionController({AdminTransaccionRepository? repository})
    : _repository = repository ?? FirebaseAdminTransaccionAdapter();

  static const List<String> modulos = [
    'deportes',
    'canchas',
    'entrenadores',
    'estudiantes',
    'resenas',
    'pagos',
    'inscripciones',
    'eventos',
    'soporte',
  ];

  final AdminTransaccionRepository _repository;
  List<Transaccion> transacciones = [];
  DateTime? desde;
  DateTime? hasta;
  String? modulo;
  String? rol;
  bool cargando = false;
  String? error;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Transaccion>>? _sub;

  List<Transaccion> get transaccionesFiltradas {
    return transacciones.where((item) {
      if (modulo != null && item.modulo != modulo) return false;
      if (rol != null && item.rol != rol) return false;
      final dia = DateTime(item.fecha.year, item.fecha.month, item.fecha.day);
      if (desde != null &&
          dia.isBefore(DateTime(desde!.year, desde!.month, desde!.day))) {
        return false;
      }
      if (hasta != null &&
          dia.isAfter(DateTime(hasta!.year, hasta!.month, hasta!.day))) {
        return false;
      }
      return true;
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.transacciones().listen((lista) {
      transacciones = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudo cargar el historial.'));
  }

  void filtrar({
    DateTime? desde,
    DateTime? hasta,
    String? modulo,
    String? rol,
  }) {
    this.desde = desde;
    this.hasta = hasta;
    this.modulo = modulo;
    this.rol = rol;
    _avisar();
  }

  void limpiarFiltros() {
    desde = null;
    hasta = null;
    modulo = null;
    rol = null;
    _avisar();
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
