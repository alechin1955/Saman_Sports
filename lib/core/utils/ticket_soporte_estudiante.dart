import 'package:saman_sports/core/constants/app_strings.dart';

/// Categorías de soporte que puede elegir el estudiante. Las claves son las
/// que se guardan en Firestore; 'pagos' es propia del estudiante.
const Map<String, String> categoriasSoporteEstudiante = {
  'cuenta': 'Cuenta y acceso',
  'disciplinas': 'Disciplinas e inscripciones',
  'pagos': 'Pagos y solvencia',
  'asistencia': 'Asistencia',
  'eventos': 'Eventos',
  'otro': 'Otro',
};

const int maximoAsuntoSoporte = 80;
const int maximoDescripcionSoporte = 500;

/// Devuelve el mensaje de error o null si el ticket es válido.
String? validarTicketEstudiante({
  required String categoria,
  required String asunto,
  required String descripcion,
}) {
  final a = asunto.trim();
  final d = descripcion.trim();
  if (!categoriasSoporteEstudiante.containsKey(categoria)) {
    return AppStrings.soporteEligeCategoria;
  }
  if (a.length < 5) return AppStrings.soporteAsuntoCorto;
  if (a.length > maximoAsuntoSoporte) return AppStrings.soporteAsuntoLargo;
  if (d.length < 10) return AppStrings.soporteDescripcionCorta;
  if (d.length > maximoDescripcionSoporte) {
    return AppStrings.soporteDescripcionLarga;
  }
  return null;
}

/// Arma el documento del ticket con la identidad tomada de la sesión y del
/// perfil, nunca de lo que escribe el estudiante. Cumple las reglas de
/// `tickets`: estado 'abierto', respuesta vacía y resueltoEn en null.
Map<String, dynamic> construirTicketEstudiante({
  required String estudianteUid,
  required Map<String, dynamic>? perfil,
  required String categoria,
  required String asunto,
  required String descripcion,
  required Object fechaServidor,
}) {
  final error = validarTicketEstudiante(
    categoria: categoria,
    asunto: asunto,
    descripcion: descripcion,
  );
  if (error != null) throw StateError(error);
  if (estudianteUid.isEmpty || perfil?['rol'] != 'estudiante') {
    throw StateError(AppStrings.sesionNoIniciada);
  }
  final nombre = '${perfil?['nombre'] ?? ''} ${perfil?['apellido'] ?? ''}'
      .trim();
  return {
    'asunto': asunto.trim(),
    'categoria': categoria,
    'descripcion': descripcion.trim(),
    'autorUid': estudianteUid,
    'autorNombre': nombre.isEmpty ? 'Estudiante' : nombre,
    'autorRol': 'estudiante',
    'estado': 'abierto',
    'respuesta': '',
    'fecha': fechaServidor,
    'resueltoEn': null,
  };
}
