import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/repositories/admin/admin_inscripcion_repository.dart';

class AdminInscripcionController extends ChangeNotifier {
  AdminInscripcionController({AdminInscripcionRepository? repository})
    : _repository = repository ?? FirebaseAdminInscripcionAdapter();

  final AdminInscripcionRepository _repository;
  List<Inscripcion> inscripciones = [];
  EstadoInscripcion? filtroEstado;
  String? filtroDeporte;
  String busqueda = '';
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Inscripcion>>? _sub;

  List<Inscripcion> get inscripcionesFiltradas {
    final texto = busqueda.trim().toLowerCase();
    return inscripciones.where((item) {
      if (filtroEstado != null && item.estado != filtroEstado) return false;
      if (filtroDeporte != null && item.deporteId != filtroDeporte) {
        return false;
      }
      if (texto.isEmpty) return true;
      return '${item.deporteNombre} ${item.estudianteUid}'
          .toLowerCase()
          .contains(texto);
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.inscripciones().listen((lista) {
      inscripciones = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar las inscripciones.'));
  }

  void filtrar({EstadoInscripcion? estado, String? deporteId}) {
    filtroEstado = estado;
    filtroDeporte = deporteId;
    _avisar();
  }

  void buscar(String texto) {
    busqueda = texto;
    _avisar();
  }

  Future<String?> cambiarEstado(Inscripcion inscripcion, String estado) {
    return _guardar(
      () => _repository.cambiarEstado(id: inscripcion.id, estado: estado),
      'Inscripción actualizada.',
    );
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
