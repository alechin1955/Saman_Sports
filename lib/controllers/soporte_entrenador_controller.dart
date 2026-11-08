import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/repositories/soporte_entrenador_repository.dart';

class SoporteEntrenadorController extends ChangeNotifier {
  SoporteEntrenadorController({SoporteEntrenadorRepository? repository})
    : _repository = repository ?? FirebaseSoporteEntrenadorAdapter();

  static const Map<String, String> categorias = {
    'cuenta': 'Cuenta y acceso',
    'disciplinas': 'Disciplinas',
    'asistencia': 'Asistencia',
    'eventos': 'Eventos',
    'otro': 'Otro',
  };
  static const int maximoAsunto = 80;
  static const int maximoDescripcion = 500;

  final SoporteEntrenadorRepository _repository;
  final List<TicketSoporte> tickets = [];
  bool cargando = false;
  bool enviando = false;
  String? error;
  String? errorFormulario;
  String? mensaje;
  bool _iniciado = false;
  bool _cerrado = false;
  StreamSubscription<List<TicketSoporte>>? _sub;

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    error = null;
    _avisar();
    try {
      _sub = _repository.tickets().listen((lista) {
        if (_cerrado) return;
        tickets
          ..clear()
          ..addAll(lista)
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
        cargando = false;
        error = null;
        _avisar();
      }, onError: (_) => _falloCarga());
    } catch (_) {
      _falloCarga();
    }
  }

  Future<bool> crear({
    required String? categoria,
    required String asunto,
    required String descripcion,
  }) async {
    if (_cerrado || enviando) return false;
    final categoriaLimpia = categoria?.trim() ?? '';
    final asuntoLimpio = asunto.trim();
    final descripcionLimpia = descripcion.trim();
    errorFormulario = _validar(
      categoria: categoriaLimpia,
      asunto: asuntoLimpio,
      descripcion: descripcionLimpia,
    );
    mensaje = null;
    if (errorFormulario != null) {
      _avisar();
      return false;
    }

    enviando = true;
    _avisar();
    try {
      final resultado = await _repository.crear(
        categoria: categoriaLimpia,
        asunto: asuntoLimpio,
        descripcion: descripcionLimpia,
      );
      if (_cerrado) return false;
      if (resultado != null) {
        errorFormulario = resultado;
        return false;
      }
      mensaje = 'Tu solicitud fue enviada a la coordinación.';
      errorFormulario = null;
      return true;
    } catch (_) {
      if (!_cerrado) {
        errorFormulario = 'No se pudo enviar la solicitud. Intenta nuevamente.';
      }
      return false;
    } finally {
      if (!_cerrado) {
        enviando = false;
        _avisar();
      }
    }
  }

  void limpiarErrorFormulario() {
    if (errorFormulario == null) return;
    errorFormulario = null;
    _avisar();
  }

  static String categoriaEtiqueta(String categoria) =>
      categorias[categoria] ?? categoria;

  String? _validar({
    required String categoria,
    required String asunto,
    required String descripcion,
  }) {
    if (!categorias.containsKey(categoria)) {
      return 'Elige una categoría.';
    }
    if (asunto.length < 5) {
      return 'El asunto debe tener al menos 5 caracteres.';
    }
    if (asunto.length > maximoAsunto) {
      return 'El asunto puede tener máximo $maximoAsunto caracteres.';
    }
    if (descripcion.length < 10) {
      return 'Describe el problema con al menos 10 caracteres.';
    }
    if (descripcion.length > maximoDescripcion) {
      return 'La descripción puede tener máximo $maximoDescripcion caracteres.';
    }
    return null;
  }

  void _falloCarga() {
    if (_cerrado) return;
    cargando = false;
    error = 'No se pudieron cargar tus solicitudes de soporte.';
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
