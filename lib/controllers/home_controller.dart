import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/datos_ejemplo.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_publico.dart';
import 'package:saman_sports/models/resena.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    Stream<List<Map<String, dynamic>>> Function()? deportesOrigen,
    Stream<List<Map<String, dynamic>>> Function()? entrenadoresOrigen,
    Stream<List<Map<String, dynamic>>> Function()? resenasOrigen,
  })  : _deportesOrigen = deportesOrigen ?? FirebaseServices.streamDeportes,
        _entrenadoresOrigen = entrenadoresOrigen ?? FirebaseServices.streamEntrenadores,
        _resenasOrigen = resenasOrigen ?? FirebaseServices.streamResenas;

  static const bool mostrarEjemplosSiVacio = true;

  final Stream<List<Map<String, dynamic>>> Function() _deportesOrigen;
  final Stream<List<Map<String, dynamic>>> Function() _entrenadoresOrigen;
  final Stream<List<Map<String, dynamic>>> Function() _resenasOrigen;

  List<Deporte> deportes = [];
  List<EntrenadorPublico> entrenadores = [];
  List<Resena> resenas = [];
  bool cargando = true;
  bool usandoEjemplo = false;
  bool ejemplosDeportes = false;
  bool ejemplosEntrenadores = false;
  bool ejemplosResenas = false;

  StreamSubscription<List<Map<String, dynamic>>>? _subDeportes;
  StreamSubscription<List<Map<String, dynamic>>>? _subEntrenadores;
  StreamSubscription<List<Map<String, dynamic>>>? _subResenas;
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
      if (lista.isEmpty && mostrarEjemplosSiVacio) {
        deportes = DatosEjemplo.deportes;
        ejemplosDeportes = true;
      } else {
        deportes = lista.map(Deporte.fromMap).toList();
        ejemplosDeportes = false;
      }
      _cerrarCarga();
    });
    _subEntrenadores = _escuchar(_entrenadoresOrigen, (lista) {
      _recibioEntrenadores = true;
      if (lista.isEmpty && mostrarEjemplosSiVacio) {
        entrenadores = DatosEjemplo.entrenadores;
        ejemplosEntrenadores = true;
      } else {
        entrenadores = lista.map(EntrenadorPublico.fromMap).toList();
        ejemplosEntrenadores = false;
      }
      _cerrarCarga();
    });
    _subResenas = _escuchar(_resenasOrigen, (lista) {
      _recibioResenas = true;
      if (lista.isEmpty && mostrarEjemplosSiVacio) {
        resenas = DatosEjemplo.resenas;
        ejemplosResenas = true;
      } else {
        resenas = lista.map(Resena.fromMap).toList();
        ejemplosResenas = false;
      }
      _cerrarCarga();
    });
  }

  @override
  void dispose() {
    _subDeportes?.cancel();
    _subEntrenadores?.cancel();
    _subResenas?.cancel();
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
      return origen()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: (sink) {
              sink.add(const []);
              sink.close();
            },
          )
          .listen(recibir, onError: (_) => recibir(const []));
    } catch (_) {
      recibir(const []);
      return null;
    }
  }

  void _cerrarCarga() {
    usandoEjemplo = ejemplosDeportes || ejemplosEntrenadores || ejemplosResenas;
    cargando = !(_recibioDeportes && _recibioEntrenadores && _recibioResenas);
    notifyListeners();
  }
}
