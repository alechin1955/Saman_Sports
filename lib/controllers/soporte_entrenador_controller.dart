import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/utils/ticket_soporte_entrenador.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/repositories/soporte_entrenador_repository.dart';

class SoporteEntrenadorController extends ChangeNotifier {
  SoporteEntrenadorController({SoporteEntrenadorRepository? repository})
    : _repository = repository ?? FirebaseSoporteEntrenadorAdapter();

  static const Map<String, String> categorias = categoriasSoporteEntrenador;
  static const int maximoAsunto = maximoAsuntoSoporteEntrenador;
  static const int maximoDescripcion = maximoDescripcionSoporteEntrenador;

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
    errorFormulario = validarTicketSoporteEntrenador(
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
