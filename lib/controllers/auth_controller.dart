import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/datos_registro.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/validators.dart';

class AuthController extends ChangeNotifier {
  bool cargando = false;
  bool registrando = false;
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

      final resultado = await _consultarRol(credential!.user!.uid);
      if (resultado.tipo == TipoResultadoRol.error) {
        error = AppStrings.errorConexion;
        return null;
      }
      if (resultado.destino == null) {
        await FirebaseServices.signOut();
        error = AppStrings.cuentaNoHabilitada;
        destinoActual = null;
        return null;
      }
      final destino = resultado.destino!;
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
    registrando = true;
    error = null;
    notifyListeners();
    try {
      final respuesta = await FirebaseServices.register(
        email: datos.correo.trim(),
        password: datos.clave,
      );
      final uid = respuesta.credential?.user?.uid;
      if (!respuesta.isSuccess || uid == null) {
        error = _traducirRegistro(respuesta.errorMessage);
        return false;
      }

      final AuthResponse guardado;
      try {
        guardado = await FirebaseServices.saveUserData(
          uid: uid,
          data: datos.toMap(),
        ).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        await FirebaseServices.deleteCurrentUser();
        error = AppStrings.errorConexion;
        return false;
      }
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
      registrando = false;
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

  Future<ResultadoRol> rolSesionActual() async {
    final user = FirebaseServices.currentUser;
    if (user == null) {
      destinoActual = null;
      return const ResultadoRol(tipo: TipoResultadoRol.sinRol);
    }
    final resultado = await _consultarRol(user.uid);
    destinoActual = resultado.destino;
    return resultado;
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

  Future<ResultadoRol> _consultarRol(String uid) async {
    final consulta = await FirebaseServices.consultarRol(uid: uid);
    if (consulta.error) {
      return const ResultadoRol(tipo: TipoResultadoRol.error);
    }
    final destino = _destinoDesdeRol(consulta.rol);
    if (!consulta.existe || destino == null) {
      return const ResultadoRol(tipo: TipoResultadoRol.sinRol);
    }
    return ResultadoRol(tipo: TipoResultadoRol.valido, destino: destino);
  }

  String _traducirRegistro(String? mensaje) {
    final texto = (mensaje ?? '').toLowerCase();
    if (texto.contains('already') || texto.contains('email-already-in-use')) {
      return AppStrings.correoYaRegistrado;
    }
    if (texto.contains('weak-password') || texto.contains('weak')) {
      return AppStrings.claveCorta;
    }
    if (texto.contains('invalid-email') || texto.contains('badly formatted')) {
      return AppStrings.correoInvalido;
    }
    if (texto.contains('network') || texto.contains('unavailable')) {
      return AppStrings.errorConexion;
    }
    return mensaje == null || mensaje.isEmpty
        ? AppStrings.errorInesperado
        : mensaje;
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
