import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/datos_registro.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/validators.dart';

class AuthController extends ChangeNotifier {
  bool cargando = false;
  String? error;
  bool enlaceEnviado = false;
  String? correoEnviado;
  int segundosReenvio = 0;
  DestinoLogin? destinoActual;

  Timer? _reenvio;

  Future<DestinoLogin?> iniciarSesion(
    String correo,
    String clave, {
    bool recordar = false,
  }) async {
    final mensaje = Validators.correoInstitucional(correo) ?? Validators.clave(clave);
    if (mensaje != null) {
      error = mensaje;
      notifyListeners();
      return null;
    }

    cargando = true;
    error = null;
    notifyListeners();
    try {
      await FirebaseServices.setRememberSession(recordar);
      final (credential, errorMessage) = await FirebaseServices.signIn(
        email: correo.trim(),
        password: clave,
      );
      if (errorMessage != null || credential?.user == null) {
        error = errorMessage ?? AppStrings.errorInesperado;
        return null;
      }

      final rol = await FirebaseServices.getUserRole(uid: credential!.user!.uid);
      final destino = _destinoDesdeRol(rol);
      if (destino == null) {
        await FirebaseServices.signOut();
        error = AppStrings.cuentaNoHabilitada;
        destinoActual = null;
        return null;
      }
      destinoActual = destino;
      return destino;
    } catch (_) {
      error = AppStrings.errorInesperado;
      return null;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> registrarEstudiante(DatosRegistro datos) async {
    final mensaje = _validarRegistro(datos);
    if (mensaje != null) {
      error = mensaje;
      notifyListeners();
      return false;
    }

    cargando = true;
    error = null;
    notifyListeners();
    try {
      final respuesta = await FirebaseServices.register(
        email: datos.correo.trim(),
        password: datos.clave,
      );
      final uid = respuesta.credential?.user?.uid;
      if (!respuesta.isSuccess || uid == null) {
        error = respuesta.errorMessage ?? AppStrings.errorInesperado;
        return false;
      }

      final guardado = await FirebaseServices.saveUserData(
        uid: uid,
        data: datos.toMap(),
      );
      if (!guardado.isSuccess) {
        await FirebaseServices.deleteCurrentUser();
        error = guardado.errorMessage ?? AppStrings.errorInesperado;
        return false;
      }
      destinoActual = DestinoLogin.estudiante;
      return true;
    } catch (_) {
      error = AppStrings.errorInesperado;
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> enviarEnlaceRecuperacion(String correo) async {
    final mensaje = Validators.correoInstitucional(correo);
    if (mensaje != null) {
      error = mensaje;
      notifyListeners();
      return;
    }

    cargando = true;
    error = null;
    notifyListeners();
    try {
      await FirebaseServices.sendPasswordResetEmail(email: correo.trim());
      enlaceEnviado = true;
      correoEnviado = correo.trim();
      _iniciarCuentaRegresiva();
    } catch (_) {
      error = AppStrings.errorInesperado;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> reenviarEnlace() async {
    if (segundosReenvio != 0 || correoEnviado == null) {
      return;
    }
    await enviarEnlaceRecuperacion(correoEnviado!);
  }

  void usarOtroCorreo() {
    _reenvio?.cancel();
    enlaceEnviado = false;
    correoEnviado = null;
    segundosReenvio = 0;
    error = null;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    cargando = true;
    notifyListeners();
    try {
      await FirebaseServices.signOut();
      destinoActual = null;
    } catch (_) {
      error = AppStrings.errorInesperado;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<DestinoLogin?> rolSesionActual() async {
    final user = FirebaseServices.currentUser;
    if (user == null) {
      destinoActual = null;
      return null;
    }
    final rol = await FirebaseServices.getUserRole(uid: user.uid);
    destinoActual = _destinoDesdeRol(rol);
    return destinoActual;
  }

  void reiniciarEstado() {
    _reenvio?.cancel();
    error = null;
    enlaceEnviado = false;
    correoEnviado = null;
    segundosReenvio = 0;
    notifyListeners();
  }

  void limpiarError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reenvio?.cancel();
    super.dispose();
  }

  DestinoLogin? _destinoDesdeRol(String? rol) {
    return switch (rol) {
      'estudiante' => DestinoLogin.estudiante,
      'entrenador' => DestinoLogin.entrenador,
      'administrador' => DestinoLogin.administrador,
      _ => null,
    };
  }

  String? _validarRegistro(DatosRegistro datos) {
    return Validators.nombre(datos.nombre) ??
        Validators.apellido(datos.apellido) ??
        Validators.cedula(datos.cedula) ??
        Validators.carnet(datos.carnet) ??
        Validators.telefono(datos.telefono) ??
        Validators.correoEstudiante(datos.correo) ??
        Validators.clave(datos.clave);
  }

  void _iniciarCuentaRegresiva() {
    _reenvio?.cancel();
    segundosReenvio = 60;
    _reenvio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosReenvio <= 1) {
        segundosReenvio = 0;
        timer.cancel();
      } else {
        segundosReenvio -= 1;
      }
      notifyListeners();
    });
  }
}
