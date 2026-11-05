import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/utils/validators.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/repositories/admin/admin_entrenador_repository.dart';

enum FiltroEntrenador { todos, activos, inactivos }

class AdminEntrenadorController extends ChangeNotifier {
  AdminEntrenadorController({AdminEntrenadorRepository? repository})
    : _repository = repository ?? FirebaseAdminEntrenadorAdapter();

  static const String clavesDistintas = 'Las contraseñas no coinciden.';
  static const String experienciaInvalida =
      'Los años de experiencia deben estar entre 0 y 60.';
  static const String cedulaRepetida =
      'Ya existe un entrenador con esa cédula.';
  static const String correoRepetido =
      'Ya existe un entrenador con ese correo.';
  static const String cuentaCreada = 'Cuenta de entrenador creada.';

  final AdminEntrenadorRepository _repository;
  List<EntrenadorAdmin> entrenadores = [];
  FiltroEntrenador filtro = FiltroEntrenador.todos;
  String busqueda = '';
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  int _escuchas = 0;
  Map<String, Map<String, dynamic>> _publicos = {};
  Map<String, Map<String, dynamic>> _privados = {};
  StreamSubscription<Map<String, Map<String, dynamic>>>? _publicosSub;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _privadosSub;

  int get escuchas => _escuchas;

  List<EntrenadorAdmin> get entrenadoresActivos =>
      entrenadores.where((entrenador) => entrenador.activo).toList();

  List<EntrenadorAdmin> get entrenadoresFiltrados {
    final texto = busqueda.trim().toLowerCase();
    return entrenadores.where((entrenador) {
      final visible = switch (filtro) {
        FiltroEntrenador.activos => entrenador.activo,
        FiltroEntrenador.inactivos => !entrenador.activo,
        FiltroEntrenador.todos => true,
      };
      if (!visible) return false;
      if (texto.isEmpty) return true;
      return '${entrenador.nombreCompleto} ${entrenador.especialidad} ${entrenador.cedula}'
          .toLowerCase()
          .contains(texto);
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    _escuchas++;
    cargando = true;
    _avisar();
    _publicosSub = _repository.entrenadoresPublicos().listen((mapa) {
      _publicos = mapa;
      _combinar();
    }, onError: (_) => _fallo('No se pudieron cargar los entrenadores.'));
    _privadosSub = _repository.perfilesPrivados().listen((mapa) {
      _privados = mapa;
      _combinar();
    }, onError: (_) => _fallo('No se pudieron cargar los perfiles.'));
  }

  void cambiarFiltro(FiltroEntrenador valor) {
    filtro = valor;
    _avisar();
  }

  void buscar(String texto) {
    busqueda = texto;
    _avisar();
  }

  Future<String?> crearEntrenador({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String clave,
    required String confirmarClave,
    required String telefono,
    required String disciplina,
    required String especialidad,
    required int anosExperiencia,
    required String descripcion,
  }) {
    return _guardar(() async {
      final validacion = _validar(
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: correo,
        clave: clave,
        confirmarClave: confirmarClave,
        telefono: telefono,
        anosExperiencia: anosExperiencia,
      );
      if (validacion != null) return validacion;
      return _repository.crearCuenta(
        correo: correo.trim(),
        clave: clave,
        datos: EntrenadorAdmin(
          uid: '',
          nombre: nombre.trim(),
          apellido: apellido.trim(),
          disciplina: disciplina.trim(),
          descripcion: descripcion.trim(),
          activo: true,
          especialidad: especialidad.trim(),
          anosExperiencia: anosExperiencia,
          correo: correo.trim(),
          cedula: cedula.trim(),
          telefono: telefono.trim(),
        ),
      );
    }, cuentaCreada);
  }

  Future<String?> actualizarEntrenador(EntrenadorAdmin datos) {
    return _guardar(
      () => _repository.actualizar(datos),
      'Entrenador actualizado.',
    );
  }

  Future<String?> cambiarEstado(EntrenadorAdmin entrenador, bool activo) {
    return _guardar(
      () => _repository.cambiarEstado(uid: entrenador.uid, activo: activo),
      activo ? 'Entrenador activado.' : 'Entrenador desactivado.',
    );
  }

  String? _validar({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String clave,
    required String confirmarClave,
    required String telefono,
    required int anosExperiencia,
  }) {
    final mensaje =
        Validators.nombre(nombre) ??
        Validators.apellido(apellido) ??
        Validators.cedula(cedula) ??
        Validators.correoInstitucional(correo) ??
        Validators.clave(clave) ??
        Validators.telefono(telefono);
    if (mensaje != null) return mensaje;
    if (clave != confirmarClave) return clavesDistintas;
    if (anosExperiencia < 0 || anosExperiencia > 60) return experienciaInvalida;
    final cedulaNormal = cedula.trim().toLowerCase();
    final correoNormal = correo.trim().toLowerCase();
    for (final entrenador in entrenadores) {
      if (entrenador.cedula.trim().toLowerCase() == cedulaNormal) {
        return cedulaRepetida;
      }
      if (entrenador.correo.trim().toLowerCase() == correoNormal) {
        return correoRepetido;
      }
    }
    return null;
  }

  void _combinar() {
    final uids = {
      ..._publicos.keys,
      ..._privados.keys,
    }.where((uid) => uid.isNotEmpty);
    entrenadores =
        uids
            .map(
              (uid) => EntrenadorAdmin.desdeMapas(
                uid,
                _publicos[uid] ?? const {},
                _privados[uid],
              ),
            )
            .toList()
          ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    cargando = false;
    _avisar();
  }

  Future<String?> _guardar(
    Future<String?> Function() accion,
    String exito,
  ) async {
    if (_cerrado) return 'La operación ya no está disponible.';
    guardando = true;
    error = null;
    mensaje = null;
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
    _publicosSub?.cancel();
    _privadosSub?.cancel();
    super.dispose();
  }
}
