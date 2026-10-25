import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/validators.dart';
import 'package:saman_sports/models/estudiante.dart';

/// Lee los datos de usuarios/{uid}. Devuelve null si no existe.
typedef LeerPerfil = Future<Map<String, dynamic>?> Function(String uid);

/// Guarda campos en usuarios/{uid} (escritura con merge).
typedef GuardarPerfil = Future<AuthResponse> Function(
  String uid,
  Map<String, dynamic> datos,
);

/// Controlador del panel del estudiante (Observer: sujeto concreto).
///
/// Carga el perfil del estudiante con sesión abierta y guarda los cambios
/// permitidos (nombre, apellido y teléfono). Solo habla con Firebase a
/// través de la fachada FirebaseServices. Las funciones de lectura y
/// escritura se pueden inyectar por constructor para probarlo sin Firebase.
class EstudianteController extends ChangeNotifier {
  EstudianteController({
    String? Function()? uidActual,
    LeerPerfil? leer,
    GuardarPerfil? guardar,
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _leer = leer ?? ((uid) => FirebaseServices.getUserData(uid: uid)),
       _guardar =
           guardar ??
           ((uid, datos) =>
               FirebaseServices.saveUserData(uid: uid, data: datos));

  final String? Function() _uidActual;
  final LeerPerfil _leer;
  final GuardarPerfil _guardar;

  Estudiante? estudiante;
  bool cargando = false;
  bool guardando = false;
  String? error;

  /// Lee usuarios/{uid} del estudiante con sesión abierta.
  Future<void> cargarPerfil() async {
    final uid = _uidActual();
    if (uid == null) {
      estudiante = null;
      error = AppStrings.sesionNoIniciada;
      notifyListeners();
      return;
    }

    cargando = true;
    error = null;
    notifyListeners();
    try {
      final datos = await _leer(uid).timeout(const Duration(seconds: 10));
      if (datos == null) {
        estudiante = null;
        error = AppStrings.perfilNoEncontrado;
        return;
      }
      estudiante = Estudiante.fromMap(uid, datos);
    } on TimeoutException {
      error = AppStrings.errorConexion;
    } catch (_) {
      error = AppStrings.errorInesperado;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Guarda nombre, apellido y teléfono. Devuelve true si se guardó.
  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final actual = estudiante;
    if (actual == null) {
      error = AppStrings.perfilNoEncontrado;
      notifyListeners();
      return false;
    }

    final mensaje =
        Validators.nombre(nombre) ??
        Validators.apellido(apellido) ??
        Validators.telefono(telefono);
    if (mensaje != null) {
      error = mensaje;
      notifyListeners();
      return false;
    }

    final nuevo = actual.copiaCon(
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      telefono: telefono.trim(),
    );

    guardando = true;
    error = null;
    notifyListeners();
    try {
      final respuesta = await _guardar(
        actual.uid,
        nuevo.toMapEditable(),
      ).timeout(const Duration(seconds: 10));
      if (!respuesta.isSuccess) {
        error = respuesta.errorMessage ?? AppStrings.errorInesperado;
        return false;
      }
      estudiante = nuevo;
      return true;
    } on TimeoutException {
      error = AppStrings.errorConexion;
      return false;
    } catch (_) {
      error = AppStrings.errorInesperado;
      return false;
    } finally {
      guardando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    error = null;
    notifyListeners();
  }

  /// Al cerrar sesión se olvidan los datos del estudiante anterior.
  void reiniciar() {
    estudiante = null;
    error = null;
    cargando = false;
    guardando = false;
    notifyListeners();
  }
}
