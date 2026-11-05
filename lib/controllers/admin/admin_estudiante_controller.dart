import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/repositories/admin/admin_estudiante_repository.dart';

enum FiltroEstudiante { todos, activos, inactivos, solventes, pendientes }

class AdminEstudianteController extends ChangeNotifier {
  AdminEstudianteController({AdminEstudianteRepository? repository})
    : _repository = repository ?? FirebaseAdminEstudianteAdapter();

  final AdminEstudianteRepository _repository;
  List<Estudiante> estudiantes = [];
  FiltroEstudiante filtro = FiltroEstudiante.todos;
  String busqueda = '';
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Estudiante>>? _sub;

  List<Estudiante> get estudiantesFiltrados {
    final texto = busqueda.trim().toLowerCase();
    final lista = estudiantes.where((estudiante) {
      final visible = switch (filtro) {
        FiltroEstudiante.activos => estudiante.activo,
        FiltroEstudiante.inactivos => !estudiante.activo,
        FiltroEstudiante.solventes => estudiante.solvente,
        FiltroEstudiante.pendientes => !estudiante.solvente,
        FiltroEstudiante.todos => true,
      };
      if (!visible) return false;
      if (texto.isEmpty) return true;
      return '${estudiante.nombre} ${estudiante.apellido} ${estudiante.carnet}'
          .toLowerCase()
          .contains(texto);
    }).toList();
    lista.sort((a, b) {
      final apellido = a.apellido.compareTo(b.apellido);
      return apellido != 0 ? apellido : a.nombre.compareTo(b.nombre);
    });
    return lista;
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.estudiantes().listen((lista) {
      estudiantes = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar los estudiantes.'));
  }

  void cambiarFiltro(FiltroEstudiante valor) {
    filtro = valor;
    _avisar();
  }

  void buscar(String texto) {
    busqueda = texto;
    _avisar();
  }

  Future<String?> cambiarEstado(Estudiante estudiante, bool activo) {
    return _guardar(
      () => _repository.cambiarEstado(uid: estudiante.uid, activo: activo),
      activo ? 'Estudiante activado.' : 'Estudiante desactivado.',
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
