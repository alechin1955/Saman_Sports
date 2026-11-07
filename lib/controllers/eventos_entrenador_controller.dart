import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/repositories/eventos_entrenador_repository.dart';

class EventosEntrenadorController extends ChangeNotifier {
  EventosEntrenadorController({
    EventosEntrenadorRepository? repository,
    DateTime Function()? reloj,
  }) : _repository = repository ?? FirebaseEventosEntrenadorAdapter(),
       _reloj = reloj ?? DateTime.now;

  final EventosEntrenadorRepository _repository;
  final DateTime Function() _reloj;
  List<Evento> eventos = [];
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Evento>>? _sub;

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    try {
      _sub = _repository.eventos().listen((lista) {
        if (_cerrado) return;
        eventos = [...lista]..sort((a, b) => b.fecha.compareTo(a.fecha));
        cargando = false;
        error = null;
        _avisar();
      }, onError: (_) => _falloCarga());
    } catch (_) {
      _falloCarga();
    }
  }

  Future<bool> solicitar({
    required String nombre,
    required Deporte disciplina,
    required DateTime fecha,
    required int horaInicio,
    required int horaFin,
    required String ubicacion,
    required int capacidad,
    required String descripcion,
  }) async {
    final validacion = validar(
      nombre: nombre,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      ubicacion: ubicacion,
      capacidad: capacidad,
    );
    if (validacion != null) {
      error = validacion;
      _avisar();
      return false;
    }
    guardando = true;
    error = null;
    mensaje = null;
    _avisar();
    try {
      final resultado = await _repository
          .solicitar({
            'titulo': nombre.trim(),
            'tipo': TipoEvento.evento.valor,
            'deporteId': disciplina.id,
            'deporteNombre': disciplina.nombre,
            'fecha': _fecha(fecha),
            'horaInicio': horaInicio,
            'horaFin': horaFin,
            'ubicacion': ubicacion.trim(),
            'capacidad': capacidad,
            'descripcion': descripcion.trim(),
          })
          .timeout(const Duration(seconds: 15));
      if (_cerrado) return false;
      if (resultado != null) {
        error = resultado;
        return false;
      }
      mensaje = 'Solicitud enviada. La coordinación debe aprobarla.';
      return true;
    } catch (_) {
      if (!_cerrado) error = 'No se pudo enviar la solicitud. Reintenta.';
      return false;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
  }

  String? validar({
    required String nombre,
    required DateTime fecha,
    required int horaInicio,
    required int horaFin,
    required String ubicacion,
    required int capacidad,
  }) {
    if (nombre.trim().isEmpty) return 'Escribe el nombre del evento.';
    final ahora = _reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    if (dia.isBefore(hoy)) return 'La fecha no puede estar en el pasado.';
    if (horaInicio < 0 || horaFin > 1440 || horaFin <= horaInicio) {
      return 'El horario del evento no es válido.';
    }
    if (ubicacion.trim().isEmpty) return 'Indica la ubicación.';
    if (capacidad <= 0) return 'La capacidad debe ser mayor que cero.';
    return null;
  }

  void limpiarMensajes() {
    error = null;
    mensaje = null;
    _avisar();
  }

  void _falloCarga() {
    if (_cerrado) return;
    cargando = false;
    error = 'No se pudieron cargar tus solicitudes.';
    _avisar();
  }

  String _fecha(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

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
