import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/repositories/proximos_eventos_repository.dart';

enum ModoEventos { publico, estudiante, entrenador }

class ProximosEventosController extends ChangeNotifier {
  ProximosEventosController({
    this.modo = ModoEventos.publico,
    this.uid,
    String? Function()? uidActual,
    DateTime Function()? reloj,
    ProximosEventosRepository? repositorio,
    int limite = 6,
  }) : _reloj = reloj ?? DateTime.now,
       _repositorio = repositorio ?? FirebaseProximosEventosAdapter(),
       _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid) {
    _limite = limite;
  }

  final ModoEventos modo;
  final String? uid;
  final String? Function() _uidActual;
  final DateTime Function() _reloj;
  final ProximosEventosRepository _repositorio;
  late final int _limite;
  final Map<String, EstadoParticipacion> participacion = {};
  final Map<String, int> confirmados = {};
  StreamSubscription<List<EventoPublico>>? _eventos;
  StreamSubscription<List<Map<String, dynamic>>>? _inscripciones;
  final Map<String, StreamSubscription<Object>> _detalles = {};
  List<EventoPublico> _todos = [];
  Set<String> deportesInscritos = {};
  Set<String> _filtroEntrenador = {};
  bool _cerrado = false;
  bool cargando = false;
  String? error;

  List<EventoPublico> get eventos {
    final lista = _todos.where((evento) {
      final dia = evento.dia;
      final hoy = _hoy();
      if (dia != null && dia.isBefore(hoy)) return false;
      if (modo == ModoEventos.entrenador &&
          _filtroEntrenador.isNotEmpty &&
          !_filtroEntrenador.contains(evento.deporteId)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final tope = modo == ModoEventos.publico ? _limite : 5;
    return lista.take(tope).toList();
  }

  bool puedeConfirmar(EventoPublico evento) {
    return modo == ModoEventos.estudiante &&
        evento.deporteId.isNotEmpty &&
        deportesInscritos.contains(evento.deporteId);
  }

  void iniciar() {
    if (_eventos != null || _cerrado) return;
    cargando = true;
    _avisar();
    try {
      _eventos = _repositorio
          .publicos(desdeFecha: _fecha(_hoy()), limite: _limite)
          .listen((lista) {
            _todos = lista;
            cargando = false;
            error = null;
            _escucharDetalles();
            _avisar();
          }, onError: _fallo);
      final actual = _uidSeguro();
      if (modo == ModoEventos.estudiante && actual != null) {
        _inscripciones = _repositorio.inscripciones(actual).listen((lista) {
          deportesInscritos = {
            for (final item in lista)
              if ('${item['estado'] ?? ''}' == 'pendiente' ||
                  '${item['estado'] ?? ''}' == 'confirmada')
                '${item['deporteId'] ?? ''}',
          }..remove('');
          _escucharDetalles();
          _avisar();
        }, onError: _fallo);
      }
    } catch (_) {
      cargando = false;
      _todos = [];
      _avisar();
    }
  }

  void filtrarPorDeportes(Set<String> ids) {
    _filtroEntrenador = ids;
    _escucharDetalles();
    _avisar();
  }

  Future<String?> responder(EventoPublico evento, bool asistira) async {
    final error = await _repositorio.responder(
      eventoId: evento.id,
      asistira: asistira,
    );
    if (error == null) {
      participacion[evento.id] = asistira
          ? EstadoParticipacion.confirmado
          : EstadoParticipacion.rechazado;
      _avisar();
    }
    return error;
  }

  void _escucharDetalles() {
    final actual = _uidSeguro();
    for (final evento in eventos) {
      if (_detalles.containsKey(evento.id)) continue;
      if (modo == ModoEventos.estudiante && actual != null && puedeConfirmar(evento)) {
        _detalles[evento.id] = _repositorio
            .participacion(eventoId: evento.id, uid: actual)
            .listen((estado) {
              participacion[evento.id] = _estado(estado);
              _avisar();
            });
      }
      if (modo == ModoEventos.entrenador) {
        _detalles[evento.id] = _repositorio.participantes(eventoId: evento.id).listen((
          lista,
        ) {
          confirmados[evento.id] = lista
              .where((item) => item['estado'] == 'confirmado')
              .length;
          _avisar();
        });
      }
    }
  }

  EstadoParticipacion _estado(String valor) {
    return switch (valor) {
      'confirmado' => EstadoParticipacion.confirmado,
      'rechazado' => EstadoParticipacion.rechazado,
      _ => EstadoParticipacion.sinResponder,
    };
  }

  String? _uidSeguro() {
    if (uid != null) return uid;
    if (modo != ModoEventos.estudiante) return null;
    try {
      return _uidActual();
    } catch (_) {
      return null;
    }
  }

  DateTime _hoy() {
    final ahora = _reloj();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  String _fecha(DateTime dia) {
    final mes = dia.month.toString().padLeft(2, '0');
    final numero = dia.day.toString().padLeft(2, '0');
    return '${dia.year}-$mes-$numero';
  }

  void _fallo(Object fallo) {
    cargando = false;
    error = '$fallo';
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _eventos?.cancel();
    _inscripciones?.cancel();
    for (final sub in _detalles.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
