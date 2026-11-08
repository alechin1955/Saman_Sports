const Map<String, String> categoriasSoporteEntrenador = {
  'cuenta': 'Cuenta y acceso',
  'disciplinas': 'Disciplinas',
  'asistencia': 'Asistencia',
  'eventos': 'Eventos',
  'otro': 'Otro',
};

const int maximoAsuntoSoporteEntrenador = 80;
const int maximoDescripcionSoporteEntrenador = 500;

String? validarTicketSoporteEntrenador({
  required String categoria,
  required String asunto,
  required String descripcion,
}) {
  if (!categoriasSoporteEntrenador.containsKey(categoria)) {
    return 'Elige una categoría.';
  }
  if (asunto.length < 5) {
    return 'El asunto debe tener al menos 5 caracteres.';
  }
  if (asunto.length > maximoAsuntoSoporteEntrenador) {
    return 'El asunto puede tener máximo $maximoAsuntoSoporteEntrenador caracteres.';
  }
  if (descripcion.length < 10) {
    return 'Describe el problema con al menos 10 caracteres.';
  }
  if (descripcion.length > maximoDescripcionSoporteEntrenador) {
    return 'La descripción puede tener máximo $maximoDescripcionSoporteEntrenador caracteres.';
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
    throw StateError('Sesión de entrenador requerida');
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
        : (correo.isNotEmpty ? correo : 'Entrenador'),
    'autorRol': 'entrenador',
    'estado': 'abierto',
    'respuesta': '',
    'fecha': fechaServidor,
    'resueltoEn': null,
  };
}
