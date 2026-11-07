import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/repositories/resenas_entrenador_repository.dart';

class ResenasEntrenadorController extends ChangeNotifier {
  ResenasEntrenadorController({ResenasEntrenadorRepository? repository})
    : _repository = repository ?? FirebaseResenasEntrenadorAdapter();

  final ResenasEntrenadorRepository _repository;
  List<Deporte> disciplinas = [];
  List<Resena> resenas = [];
  bool cargando = false;
  String? error;
  bool _cerrado = false;
  StreamSubscription<List<Resena>>? _sub;

  Future<void> iniciar() async {
    await _sub?.cancel();
    cargando = true;
    error = null;
    _avisar();
    try {
      disciplinas = await _repository.disciplinas().timeout(
        const Duration(seconds: 15),
      );
      final ids = disciplinas.map((disciplina) => disciplina.id).toSet();
      _sub = _repository.resenas().listen((lista) {
        if (_cerrado) return;
        resenas =
            lista.where((resena) => ids.contains(resena.deporteId)).toList()
              ..sort((a, b) => b.fecha.compareTo(a.fecha));
        cargando = false;
        error = null;
        _avisar();
      }, onError: (_) => _fallo());
    } catch (_) {
      _fallo();
    }
  }

  double get promedio {
    if (resenas.isEmpty) return 0;
    return resenas.fold<int>(0, (total, resena) => total + resena.estrellas) /
        resenas.length;
  }

  void _fallo() {
    if (_cerrado) return;
    cargando = false;
    error = 'No se pudieron cargar las reseñas de tus disciplinas.';
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
