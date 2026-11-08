import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/eventos_entrenador_repository.dart';

class EventosEntrenadorController extends ChangeNotifier {
  EventosEntrenadorController({
    EventosEntrenadorRepository? repository,
    DateTime Function()? reloj,
    this.timeoutSolicitud = const Duration(seconds: 15),
  }) : _repository = repository ?? FirebaseEventosEntrenadorAdapter(),
       _reloj = reloj ?? DateTime.now;

  final EventosEntrenadorRepository _repository;
  final DateTime Function() _reloj;
  final Duration timeoutSolicitud;
  List<Evento> eventos = [];
  List<Cancha> canchas = [];
  List<ReservaHorario> reservasCancha = [];
  bool cargando = false;
  bool cargandoCanchas = false;
  bool cargandoOcupacion = false;
  bool guardando = false;
  String? error;
  String? errorCanchas;
  String? errorOcupacion;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  String? _canchaObservada;
  StreamSubscription<List<Evento>>? _sub;
  StreamSubscription<List<Cancha>>? _canchasSub;
  StreamSubscription<List<ReservaHorario>>? _reservasSub;

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    cargandoCanchas = true;
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
    try {
      _canchasSub = _repository.canchas().listen((lista) {
        if (_cerrado) return;
        canchas = lista.where((cancha) => cancha.activa).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
        cargandoCanchas = false;
        errorCanchas = null;
        _avisar();
      }, onError: (_) => _falloCanchas());
    } catch (_) {
      _falloCanchas();
    }
  }

  void observarCancha(String? canchaId) {
    _reservasSub?.cancel();
    _canchaObservada = canchaId;
    reservasCancha = [];
    errorOcupacion = null;
    if (canchaId == null || canchaId.isEmpty || _cerrado) {
      cargandoOcupacion = false;
      _avisar();
      return;
    }
    cargandoOcupacion = true;
    _avisar();
    try {
      _reservasSub = _repository.reservasCancha(canchaId).listen((lista) {
        if (_cerrado || _canchaObservada != canchaId) return;
        reservasCancha = lista;
        cargandoOcupacion = false;
        errorOcupacion = null;
        _avisar();
      }, onError: (_) => _falloOcupacion(canchaId));
    } catch (_) {
      _falloOcupacion(canchaId);
    }
  }

  Future<bool> solicitar({
    required String nombre,
    required Deporte disciplina,
    required Cancha cancha,
    required DateTime fecha,
    required int horaInicio,
    required int horaFin,
    required int capacidad,
    required String descripcion,
  }) async {
    final validacion = validar(
      nombre: nombre,
      cancha: cancha,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
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
            'canchaId': cancha.id,
            'fecha': _fecha(fecha),
            'horaInicio': horaInicio,
            'horaFin': horaFin,
            'capacidad': capacidad,
            'descripcion': descripcion.trim(),
          })
          .timeout(timeoutSolicitud);
      if (_cerrado) return false;
      if (resultado != null) {
        error = resultado;
        return false;
      }
      mensaje = 'Solicitud enviada. La coordinación debe aprobarla.';
      return true;
    } on TimeoutException {
      if (!_cerrado) {
        mensaje = 'La solicitud se está procesando. Revisa la lista en unos instantes.';
      }
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
    required Cancha cancha,
    required DateTime fecha,
    required int horaInicio,
    required int horaFin,
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
    if (!cancha.activa || !canchas.any((item) => item.id == cancha.id)) {
      return 'Elige una cancha activa.';
    }
    if (_canchaObservada != cancha.id || cargandoOcupacion) {
      return 'Espera mientras revisamos la disponibilidad de la cancha.';
    }
    if (errorOcupacion != null) return errorOcupacion;
    final choque = choqueHorario(
      cancha: cancha,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
    );
    if (choque != null) return choque;
    if (capacidad <= 0) return 'La capacidad debe ser mayor que cero.';
    return null;
  }

  String? choqueHorario({
    required Cancha cancha,
    required DateTime fecha,
    required int horaInicio,
    required int horaFin,
  }) {
    final nueva = ReservaHorario(
      id: '',
      canchaId: cancha.id,
      canchaNombre: cancha.nombre,
      dia: fecha.weekday,
      horaInicio: horaInicio,
      horaFin: horaFin,
      fecha: _fecha(fecha),
      tipo: TipoReserva.evento,
      refId: '',
      refNombre: '',
      activa: true,
    );
    final choque = buscarChoque(
      nuevas: [nueva],
      existentes: reservasCancha
          .where((reserva) => reserva.canchaId == cancha.id)
          .toList(),
    );
    return choque == null ? null : mensajeChoque(choque);
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

  void _falloCanchas() {
    if (_cerrado) return;
    cargandoCanchas = false;
    errorCanchas = 'No se pudieron cargar las canchas activas.';
    _avisar();
  }

  void _falloOcupacion(String canchaId) {
    if (_cerrado || _canchaObservada != canchaId) return;
    cargandoOcupacion = false;
    errorOcupacion = 'No se pudo revisar la disponibilidad de la cancha.';
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
    _canchasSub?.cancel();
    _reservasSub?.cancel();
    super.dispose();
  }
}
