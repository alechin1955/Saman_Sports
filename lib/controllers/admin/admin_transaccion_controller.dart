import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/repositories/admin/admin_transaccion_repository.dart';
import 'package:saman_sports/repositories/admin/resolutor_nombres_repository.dart';

class AdminTransaccionController extends ChangeNotifier {
  AdminTransaccionController({
    AdminTransaccionRepository? repository,
    ResolutorNombresAdmin? resolutor,
  }) : _repository = repository ?? FirebaseAdminTransaccionAdapter(),
       _resolutor = resolutor ??
           (repository == null ? FirebaseResolutorNombresAdmin() : null);

  static const List<String> modulos = [
    'deportes',
    'canchas',
    'entrenadores',
    'estudiantes',
    'resenas',
    'pagos',
    'inscripciones',
    'eventos',
    'soporte',
  ];

  final AdminTransaccionRepository _repository;
  final ResolutorNombresAdmin? _resolutor;
  final Map<String, String> _nombres = {};
  int _consulta = 0;
  static final RegExp _token = RegExp(
    r'\b[A-Za-z0-9]{20,}(?:_[A-Za-z0-9]{15,})?\b',
  );
  static const String _fraseFecha =
      'La fecha es la del momento de verificar, no una fecha bancaria.';
  List<Transaccion> transacciones = [];
  DateTime? desde;
  DateTime? hasta;
  String? modulo;
  String? rol;
  bool cargando = false;
  String? error;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Transaccion>>? _sub;

  List<Transaccion> get transaccionesFiltradas {
    return transacciones.where((item) {
      if (modulo != null && item.modulo != modulo) return false;
      if (rol != null && item.rol != rol) return false;
      final dia = DateTime(item.fecha.year, item.fecha.month, item.fecha.day);
      if (desde != null &&
          dia.isBefore(DateTime(desde!.year, desde!.month, desde!.day))) {
        return false;
      }
      if (hasta != null &&
          dia.isAfter(DateTime(hasta!.year, hasta!.month, hasta!.day))) {
        return false;
      }
      return true;
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _sub = _repository.transacciones().listen((lista) {
      transacciones = lista;
      cargando = false;
      _avisar();
      _resolver(lista);
    }, onError: (_) => _fallo('No se pudo cargar el historial.'));
  }

  String descripcionVisible(Transaccion item) {
    if (_resolutor == null) return item.descripcion;
    if (item.legible) return item.descripcion;
    var texto = item.descripcion.replaceAll(_fraseFecha, '').trim();
    final tokens = _token
        .allMatches(item.descripcion)
        .map((coincidencia) => coincidencia.group(0)!)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final token in tokens) {
      final visible = _nombres[token];
      if (visible != null) texto = texto.replaceAll(token, visible);
    }
    return texto;
  }

  void filtrar({
    DateTime? desde,
    DateTime? hasta,
    String? modulo,
    String? rol,
  }) {
    this.desde = desde;
    this.hasta = hasta;
    this.modulo = modulo;
    this.rol = rol;
    _avisar();
  }

  void limpiarFiltros() {
    desde = null;
    hasta = null;
    modulo = null;
    rol = null;
    _avisar();
  }

  Future<void> _resolver(List<Transaccion> lista) async {
    final consulta = ++_consulta;
    final resolutor = _resolutor;
    if (resolutor == null || _cerrado) return;
    final pendientes = <String>[];
    for (final item in lista) {
      if (item.legible) continue;
      for (final coincidencia in _token.allMatches(item.descripcion)) {
        final token = coincidencia.group(0)!;
        if (_nombres.containsKey(token) || pendientes.contains(token)) continue;
        pendientes.add(token);
        if (pendientes.length == 100) break;
      }
      if (pendientes.length == 100) break;
    }
    for (final token in pendientes) {
      if (_cerrado || consulta != _consulta) return;
      _nombres[token] = await _textoToken(resolutor, token, lista);
      _avisar();
    }
  }

  Future<String> _textoToken(
    ResolutorNombresAdmin resolutor,
    String token,
    List<Transaccion> lista,
  ) async {
    if (token.contains('_')) {
      final partes = token.split('_');
      if (partes.length == 2) {
        final estudiante = await resolutor.nombre('usuarios', partes[0]);
        final deporte = await resolutor.nombre('deportes', partes[1]);
        if (estudiante != null && deporte != null) {
          return 'de $estudiante en $deporte';
        }
      }
    }
    for (final coleccion in _colecciones(_moduloDe(token, lista))) {
      final nombre = await resolutor.nombre(coleccion, token);
      if (nombre != null && nombre.trim().isNotEmpty) return nombre;
    }
    return AppStrings.adminRegistroNoDisponible;
  }

  String _moduloDe(String token, List<Transaccion> lista) {
    for (final item in lista) {
      if (!item.legible && item.descripcion.contains(token)) return item.modulo;
    }
    return 'otro';
  }

  List<String> _colecciones(String modulo) {
    return switch (modulo) {
      'inscripciones' => ['usuarios', 'deportes'],
      'pagos' => ['pagos', 'usuarios'],
      'estudiantes' => ['usuarios'],
      'entrenadores' => ['usuarios', 'deportes'],
      'deportes' => ['deportes'],
      'canchas' => ['canchas'],
      'eventos' => ['eventos'],
      'resenas' => ['resenas'],
      'soporte' => ['tickets'],
      _ => ['usuarios', 'deportes'],
    };
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
