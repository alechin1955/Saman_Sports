import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/validators.dart';

class CambiarClaveController extends ChangeNotifier {
  CambiarClaveController({
    Future<AuthResponse> Function(String actual, String nueva)? cambiar,
  }) : _cambiar = cambiar ?? _cambiarFirebase;

  final Future<AuthResponse> Function(String actual, String nueva) _cambiar;
  bool guardando = false;
  String? error;
  bool exito = false;
  bool _cerrado = false;

  Future<bool> guardar({
    required String actual,
    required String nueva,
    required String confirmar,
  }) async {
    final mensaje =
        Validators.clave(nueva) ??
        Validators.confirmarClave(confirmar, nueva) ??
        (nueva == actual ? AppStrings.claveIgualActual : null);
    if (mensaje != null) {
      error = mensaje;
      exito = false;
      _avisar();
      return false;
    }
    guardando = true;
    error = null;
    exito = false;
    _avisar();
    try {
      final respuesta = await _cambiar(actual, nueva);
      if (_cerrado) return false;
      if (!respuesta.isSuccess) {
        error = respuesta.errorMessage ?? AppStrings.errorInesperado;
        return false;
      }
      exito = true;
      return true;
    } catch (_) {
      if (!_cerrado) error = AppStrings.errorInesperado;
      return false;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}

Future<AuthResponse> _cambiarFirebase(String actual, String nueva) {
  return FirebaseServices.cambiarClave(claveActual: actual, claveNueva: nueva);
}
