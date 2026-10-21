import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/constants/dominios.dart';

class Validators {
  static final RegExp _correo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _nombre = RegExp(
    r'^[A-Za-zÁÉÍÓÚÜáéíóúüÑñ]+(?: [A-Za-zÁÉÍÓÚÜáéíóúüÑñ]+)*$',
  );
  static final RegExp _cedula = RegExp(r'^(?:[VvEe]-)?\d{6,9}$');
  static final RegExp _carnet = RegExp(r'^\d{8,12}$');
  static final RegExp _telefono = RegExp(r'^04(?:12|14|16|22|24|26)\d{7}$');

  static bool esCorreoEstudiante(String correo) {
    return correo.trim().toLowerCase().endsWith(Dominios.estudiante);
  }

  static bool esCorreoInstitucional(String correo) {
    final normalizado = correo.trim().toLowerCase();
    return normalizado.endsWith(Dominios.estudiante) ||
        normalizado.endsWith(Dominios.personal);
  }

  static String? correoEstudiante(String? valor) {
    final correo = _texto(valor);
    if (correo == null) {
      return AppStrings.campoObligatorio;
    }
    if (!_correo.hasMatch(correo)) {
      return AppStrings.correoInvalido;
    }
    if (!esCorreoEstudiante(correo)) {
      return AppStrings.soloCorreoEstudiante;
    }
    return null;
  }

  static String? correoInstitucional(String? valor) {
    final correo = _texto(valor);
    if (correo == null) {
      return AppStrings.campoObligatorio;
    }
    if (!_correo.hasMatch(correo) || !esCorreoInstitucional(correo)) {
      return AppStrings.correoInstitucionalInvalido;
    }
    return null;
  }

  static String? clave(String? valor) {
    final texto = _texto(valor);
    if (texto == null) {
      return AppStrings.campoObligatorio;
    }
    if (texto.length < 6) {
      return AppStrings.claveCorta;
    }
    return null;
  }

  static String? confirmarClave(String? valor, String clave) {
    final confirmacion = _texto(valor);
    if (confirmacion == null) {
      return AppStrings.campoObligatorio;
    }
    if (confirmacion != clave) {
      return AppStrings.clavesNoCoinciden;
    }
    return null;
  }

  static String? nombre(String? valor) {
    return _nombreOApellido(valor);
  }

  static String? apellido(String? valor) {
    return _nombreOApellido(valor);
  }

  static String? cedula(String? valor) {
    final texto = _texto(valor);
    if (texto == null) {
      return AppStrings.campoObligatorio;
    }
    if (!_cedula.hasMatch(texto)) {
      return AppStrings.cedulaInvalida;
    }
    return null;
  }

  static String? carnet(String? valor) {
    final texto = _texto(valor);
    if (texto == null) {
      return AppStrings.campoObligatorio;
    }
    if (!_carnet.hasMatch(texto)) {
      return AppStrings.carnetInvalido;
    }
    return null;
  }

  static String? telefono(String? valor) {
    final texto = _texto(valor);
    if (texto == null) {
      return AppStrings.campoObligatorio;
    }
    final digitos = texto.replaceAll(RegExp(r'[\s-]'), '');
    if (!_telefono.hasMatch(digitos)) {
      return AppStrings.telefonoInvalido;
    }
    return null;
  }

  static String? _nombreOApellido(String? valor) {
    final texto = _texto(valor);
    if (texto == null) {
      return AppStrings.campoObligatorio;
    }
    if (texto.length < 2 || texto.length > 40 || !_nombre.hasMatch(texto)) {
      return AppStrings.nombreInvalido;
    }
    return null;
  }

  static String? _texto(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return null;
    }
    return texto;
  }
}
