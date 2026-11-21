import 'package:saman_sports/core/constants/app_strings.dart';
const Map<String, String> categoriasSoporteEntrenador = {
  'cuenta': AppStrings.entCuentaAcceso,
  'disciplinas': AppStrings.disciplinas,
  'asistencia': AppStrings.asistencia,
  'eventos': AppStrings.adminEventos,
  'otro': AppStrings.entOtro,
};

const int maximoAsuntoSoporteEntrenador = 80;
const int maximoDescripcionSoporteEntrenador = 500;

String? validarTicketSoporteEntrenador({
  required String categoria,
  required String asunto,
  required String descripcion,
}) {
  if (!categoriasSoporteEntrenador.containsKey(categoria)) {
    return AppStrings.entEligeCategoria;
  }
  if (asunto.length < 5) {
    return AppStrings.entAsuntoCorto;
  }
  if (asunto.length > maximoAsuntoSoporteEntrenador) {
    return AppStrings.entAsuntoMaximo(maximoAsuntoSoporteEntrenador);
  }
  if (descripcion.length < 10) {
    return AppStrings.entDescripcionCorta;
  }
  if (descripcion.length > maximoDescripcionSoporteEntrenador) {
    return AppStrings.entDescripcionMaxima(maximoDescripcionSoporteEntrenador);
  }
  return null;
}

Map<String, dynamic> construirTicketSoporteEntrenador({
  required String entrenadorUid,
  required Map<String, dynamic>? perfil,
  required String categoria,
  required String asunto,
  required String descripcion,
  required Object fechaServidor,
}) {
  final categoriaLimpia = categoria.trim();
  final asuntoLimpio = asunto.trim();
  final descripcionLimpia = descripcion.trim();
  final error = validarTicketSoporteEntrenador(
    categoria: categoriaLimpia,
    asunto: asuntoLimpio,
    descripcion: descripcionLimpia,
  );
  if (error != null) throw StateError(error);
  if (entrenadorUid.trim().isEmpty || perfil?['rol'] != 'entrenador') {
    throw StateError(AppStrings.entSesionEntrenador);
  }

  final nombre = [
    perfil?['nombre'],
    perfil?['apellido'],
  ].whereType<String>().where((parte) => parte.trim().isNotEmpty).join(' ');
  final correo = '${perfil?['correo'] ?? ''}'.trim();

  return {
    'asunto': asuntoLimpio,
    'categoria': categoriaLimpia,
    'descripcion': descripcionLimpia,
    'autorUid': entrenadorUid,
    'autorNombre': nombre.isNotEmpty
        ? nombre
        : (correo.isNotEmpty ? correo : AppStrings.entNombreFallback),
    'autorRol': 'entrenador',
    'estado': 'abierto',
    'respuesta': '',
    'fecha': fechaServidor,
    'resueltoEn': null,
  };
}
