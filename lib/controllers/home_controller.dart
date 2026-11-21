import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/models/entrenador_publico.dart';
import 'package:saman_sports/models/resena.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    Stream<List<Map<String, dynamic>>> Function()? deportesOrigen,
    Stream<List<Map<String, dynamic>>> Function()? entrenadoresOrigen,
    Stream<List<Map<String, dynamic>>> Function()? resenasOrigen,
    Stream<List<Map<String, dynamic>>> Function()? eventosOrigen,
  })  : _deportesOrigen = deportesOrigen ?? FirebaseServices.streamDeportes,
        _entrenadoresOrigen = entrenadoresOrigen ?? FirebaseServices.streamEntrenadores,
        _resenasOrigen = resenasOrigen ?? FirebaseServices.streamResenas,
        _eventosOrigen = eventosOrigen ?? _eventosDeHoy;

  final Stream<List<Map<String, dynamic>>> Function() _deportesOrigen;
  final Stream<List<Map<String, dynamic>>> Function() _entrenadoresOrigen;
  final Stream<List<Map<String, dynamic>>> Function() _resenasOrigen;
  final Stream<List<Map<String, dynamic>>> Function() _eventosOrigen;

  List<Deporte> deportes = [];
  List<EventoPublico> proximosEventos = [];
  List<EntrenadorPublico> entrenadores = [];
  List<Resena> resenas = [];
  bool cargando = true;

  StreamSubscription<List<Map<String, dynamic>>>? _subDeportes;
  StreamSubscription<List<Map<String, dynamic>>>? _subEntrenadores;
  StreamSubscription<List<Map<String, dynamic>>>? _subResenas;
  StreamSubscription<List<Map<String, dynamic>>>? _subEventos;
  var _recibioDeportes = false;
  var _recibioEntrenadores = false;
  var _recibioResenas = false;

  int get totalDisciplinas => deportes.length;
  int get totalEntrenadores => entrenadores.length;
  int get totalResenas => resenas.length;

  double get promedioEstrellas {
    if (resenas.isEmpty) return 0;
    final suma = resenas.fold<int>(0, (total, resena) => total + resena.estrellas);
    return (suma / resenas.length * 10).round() / 10;
  }

  void iniciar() {
    if (_subDeportes != null) return;
    _subDeportes = _escuchar(_deportesOrigen, (lista) {
      _recibioDeportes = true;
      deportes = lista.map(Deporte.fromMap).toList();
      _cerrarCarga();
    });
    _subEntrenadores = _escuchar(_entrenadoresOrigen, (lista) {
      _recibioEntrenadores = true;
      entrenadores = lista.map(EntrenadorPublico.fromMap).toList();
      _cerrarCarga();
    });
    _subResenas = _escuchar(_resenasOrigen, (lista) {
      _recibioResenas = true;
      resenas = lista.map(Resena.fromMap).toList();
      _cerrarCarga();
    });
    _subEventos = _escuchar(_eventosOrigen, (lista) {
      proximosEventos = lista
          .map((mapa) => EventoPublico.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList();
      notifyListeners();
    });
  }

  static Stream<List<Map<String, dynamic>>> _eventosDeHoy() {
    final hoy = DateTime.now();
    final mes = hoy.month.toString().padLeft(2, '0');
    final dia = hoy.day.toString().padLeft(2, '0');
    return FirebaseServices.streamEventosPublicos(
      desdeFecha: '${hoy.year}-$mes-$dia',
      limite: 6,
    );
  }

  @override
  void dispose() {
    _subDeportes?.cancel();
    _subEntrenadores?.cancel();
    _subResenas?.cancel();
    _subEventos?.cancel();
    super.dispose();
  }

  StreamSubscription<List<Map<String, dynamic>>>? _escuchar(
    Stream<List<Map<String, dynamic>>> Function() origen,
    void Function(List<Map<String, dynamic>> lista) alRecibir,
  ) {
    void recibir(List<Map<String, dynamic>> lista) {
      Future.microtask(() => alRecibir(lista));
    }

    try {
      return origen().listen(recibir, onError: (_) => recibir(const []));
    } catch (_) {
      recibir(const []);
      return null;
    }
  }

  void _cerrarCarga() {
    cargando = !(_recibioDeportes && _recibioEntrenadores && _recibioResenas);
    notifyListeners();
  }
}
