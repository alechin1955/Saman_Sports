import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart'
    show LeerPerfil;
import 'package:saman_sports/controllers/explorar_deportes_controller.dart'
    show OrigenDeportes;
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/constants/datos_ejemplo.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/resena.dart';

typedef OrigenMisResenas = Stream<List<Map<String, dynamic>>> Function(
  String uid,
);
typedef CrearResena = Future<AuthResponse> Function(Map<String, dynamic> data);
typedef ActualizarResena = Future<AuthResponse> Function(
  String id,
  Map<String, dynamic> data,
);
typedef EliminarResena = Future<AuthResponse> Function(String id);

/// Controlador de "Comunidad" (Observer: sujeto concreto).
///
/// Escucha en vivo las reseñas del estudiante y le permite publicar,
/// editar y eliminar las suyas. Solo usa Firebase a través de la fachada.
class ComunidadController extends ChangeNotifier {
  ComunidadController({
    String? Function()? uidActual,
    LeerPerfil? leerPerfil,
    OrigenMisResenas? misResenasOrigen,
    OrigenDeportes? deportesOrigen,
    CrearResena? crear,
    ActualizarResena? actualizar,
    EliminarResena? eliminar,
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _leerPerfil =
           leerPerfil ?? ((uid) => FirebaseServices.getUserData(uid: uid)),
       _misResenasOrigen =
           misResenasOrigen ??
           ((uid) => FirebaseServices.streamMisResenas(uid: uid)),
       _deportesOrigen = deportesOrigen ?? FirebaseServices.streamDeportes,
       _crear = crear ?? ((data) => FirebaseServices.crearResena(data: data)),
       _actualizar =
           actualizar ??
           ((id, data) =>
               FirebaseServices.actualizarResena(id: id, data: data)),
       _eliminar =
           eliminar ?? ((id) => FirebaseServices.eliminarResena(id: id));

  static const int minimoComentario = 10;
  static const int maximoComentario = 300;

  final String? Function() _uidActual;
  final LeerPerfil _leerPerfil;
  final OrigenMisResenas _misResenasOrigen;
  final OrigenDeportes _deportesOrigen;
  final CrearResena _crear;
  final ActualizarResena _actualizar;
  final EliminarResena _eliminar;

  List<Resena> misResenas = [];
  List<Deporte> deportes = [];
  String autorNombre = '';
  bool cargando = true;
  bool enviando = false;
  String? error;
  String? errorFormulario;

  StreamSubscription<List<Map<String, dynamic>>>? _subResenas;
  StreamSubscription<List<Map<String, dynamic>>>? _subDeportes;
  Timer? _espera;

  /// Empieza a escuchar las reseñas del estudiante y los deportes.
  Future<void> iniciar() async {
    _cancelar();
    final uid = _uidActual();
    if (uid == null) {
      cargando = false;
      error = AppStrings.sesionNoIniciada;
      notifyListeners();
      return;
    }

    cargando = true;
    error = null;
    notifyListeners();

    _espera = Timer(const Duration(seconds: 5), () {
      if (!cargando) return;
      cargando = false;
      error = AppStrings.errorConexion;
      notifyListeners();
    });

    _subDeportes = _escuchar(_deportesOrigen, (lista) {
      deportes = lista.isEmpty
          ? DatosEjemplo.deportes
          : lista.map(Deporte.fromMap).toList();
      notifyListeners();
    });

    _subResenas = _escuchar(() => _misResenasOrigen(uid), (lista) {
      _espera?.cancel();
      misResenas = lista.map(Resena.fromMap).toList();
      cargando = false;
      error = null;
      notifyListeners();
    });

    autorNombre = await _nombreAutor(uid);
  }

  /// Valida una reseña. Devuelve el mensaje de error o null si es válida.
  String? validar({
    required Deporte? deporte,
    required int estrellas,
    required String comentario,
    bool pideDeporte = true,
  }) {
    if (pideDeporte && deporte == null) return AppStrings.elegirDisciplinaError;
    if (estrellas < 1 || estrellas > 5) return AppStrings.elegirEstrellasError;
    final largo = comentario.trim().length;
    if (largo < minimoComentario) return AppStrings.comentarioCorto;
    if (largo > maximoComentario) return AppStrings.comentarioLargo;
    return null;
  }

  Future<bool> publicar({
    required Deporte? deporte,
    required int estrellas,
    required String comentario,
  }) async {
    final uid = _uidActual();
    final mensaje = uid == null
        ? AppStrings.sesionNoIniciada
        : validar(
            deporte: deporte,
            estrellas: estrellas,
            comentario: comentario,
          );
    if (mensaje != null) {
      errorFormulario = mensaje;
      notifyListeners();
      return false;
    }
    final elegido = deporte!;
    return _enviar(
      () => _crear({
        'autorUid': uid,
        'autorNombre': autorNombre,
        'disciplina': elegido.nombre,
        'deporteId': elegido.id,
        'estrellas': estrellas,
        'comentario': comentario.trim(),
      }),
    );
  }

  Future<bool> editar(
    Resena resena, {
    required int estrellas,
    required String comentario,
  }) async {
    final mensaje = validar(
      deporte: null,
      estrellas: estrellas,
      comentario: comentario,
      pideDeporte: false,
    );
    if (mensaje != null) {
      errorFormulario = mensaje;
      notifyListeners();
      return false;
    }
    return _enviar(
      () => _actualizar(resena.id, {
        'estrellas': estrellas,
        'comentario': comentario.trim(),
      }),
    );
  }

  Future<bool> eliminar(Resena resena) => _enviar(() => _eliminar(resena.id));

  void limpiarErrorFormulario() {
    errorFormulario = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelar();
    super.dispose();
  }

  Future<bool> _enviar(Future<AuthResponse> Function() accion) async {
    enviando = true;
    errorFormulario = null;
    notifyListeners();
    try {
      final respuesta = await accion().timeout(const Duration(seconds: 10));
      if (!respuesta.isSuccess) {
        errorFormulario = respuesta.errorMessage ?? AppStrings.errorInesperado;
        return false;
      }
      return true;
    } on TimeoutException {
      errorFormulario = AppStrings.errorConexion;
      return false;
    } catch (_) {
      errorFormulario = AppStrings.errorInesperado;
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  StreamSubscription<List<Map<String, dynamic>>>? _escuchar(
    Stream<List<Map<String, dynamic>>> Function() origen,
    void Function(List<Map<String, dynamic>> lista) alRecibir,
  ) {
    try {
      return origen().listen(alRecibir, onError: (_) => alRecibir(const []));
    } catch (_) {
      alRecibir(const []);
      return null;
    }
  }

  /// Nombre público del autor, por ejemplo "María G.".
  Future<String> _nombreAutor(String uid) async {
    try {
      final datos = await _leerPerfil(uid).timeout(const Duration(seconds: 10));
      final nombre = '${datos?['nombre'] ?? ''}'.trim();
      final apellido = '${datos?['apellido'] ?? ''}'.trim();
      if (nombre.isEmpty) return '';
      return apellido.isEmpty
          ? nombre
          : '$nombre ${apellido[0].toUpperCase()}.';
    } catch (_) {
      return '';
    }
  }

  void _cancelar() {
    _espera?.cancel();
    _subResenas?.cancel();
    _subDeportes?.cancel();
  }
}
