import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/repositories/admin/admin_resena_repository.dart';

class ResenaModerable {
  const ResenaModerable({required this.resena, required this.visible});

  final Resena resena;
  final bool visible;
}

enum FiltroResena { todas, visibles, ocultas }

class AdminResenaController extends ChangeNotifier {
  AdminResenaController({AdminResenaRepository? repository})
    : _repository = repository ?? FirebaseAdminResenaAdapter();

  final AdminResenaRepository _repository;
  List<ResenaModerable> resenas = [];
  FiltroResena filtro = FiltroResena.todas;
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<({Resena resena, bool visible})>>? _sub;

  int get ocultas => resenas.where((item) => !item.visible).length;

  List<ResenaModerable> get resenasFiltradas {
    return resenas.where((item) {
      return switch (filtro) {
        FiltroResena.visibles => item.visible,
        FiltroResena.ocultas => !item.visible,
        FiltroResena.todas => true,
      };
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.resenas().listen((lista) {
      resenas = lista
          .map(
            (item) =>
                ResenaModerable(resena: item.resena, visible: item.visible),
          )
          .toList();
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar las reseñas.'));
  }

  void cambiarFiltro(FiltroResena valor) {
    filtro = valor;
    _avisar();
  }

  Future<String?> cambiarVisibilidad(ResenaModerable item, bool visible) {
    return _guardar(
      () =>
          _repository.cambiarVisibilidad(id: item.resena.id, visible: visible),
      visible ? 'Reseña visible.' : 'Reseña oculta.',
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
