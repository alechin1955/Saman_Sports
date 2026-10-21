import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/datos_registro.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/constants/dominios.dart';
import 'package:saman_sports/core/utils/validators.dart';

class AuthController extends ChangeNotifier {
  bool cargando = false;
  String? error;
  bool enlaceEnviado = false;
  String? correoEnviado;
  int segundosReenvio = 0;

  Timer? _reenvio;

  static DestinoLogin? destinoDesdeCorreo(String? correo) {
    final normalizado = correo?.trim().toLowerCase() ?? '';
    if (normalizado.endsWith(Dominios.estudiante)) {
      return DestinoLogin.estudiante;
    }
    if (normalizado.endsWith(Dominios.personal)) {
      return DestinoLogin.entrenador;
    }
    return null;
  }

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
      await _recordarSesion(recordar);
      final (credential, errorMessage) = await FirebaseServices.signIn(
        email: correo.trim(),
        password: clave,
      );
      if (errorMessage != null || credential?.user == null) {
        error = errorMessage ?? AppStrings.errorInesperado;
        return null;
      }

      final destino = destinoDesdeCorreo(credential!.user!.email ?? correo);
      if (destino == null) {
        await FirebaseAuth.instance.signOut();
        error = AppStrings.cuentaNoHabilitada;
        return null;
      }
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
      if (!respuesta.isSuccess || respuesta.credential?.user == null) {
        error = respuesta.errorMessage ?? AppStrings.errorInesperado;
        return false;
      }
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
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: correo.trim());
      } on FirebaseAuthException {
        // La confirmación es siempre la misma, exista o no la cuenta.
      }
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
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      error = AppStrings.errorInesperado;
    } finally {
      cargando = false;
      notifyListeners();
    }
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

  Future<void> _recordarSesion(bool recordar) async {
    await FirebaseAuth.instance.setPersistence(
      recordar ? Persistence.LOCAL : Persistence.SESSION,
    );
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
