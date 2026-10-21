// Esquema Firestore entrenadores/{uid}:
// nombre, apellido, disciplina, descripcion, fotoUrl (opcional), activo (bool).
// Perfil público: sin cédula ni teléfono.

class EntrenadorPublico {
  const EntrenadorPublico({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.disciplina,
    required this.descripcion,
    this.fotoUrl,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String disciplina;
  final String descripcion;
  final String? fotoUrl;

  String get iniciales {
    final primera = nombre.isEmpty ? '' : nombre[0];
    final segunda = apellido.isEmpty ? '' : apellido[0];
    return '$primera$segunda'.toUpperCase();
  }

  factory EntrenadorPublico.fromMap(Map<String, dynamic> map) {
    final foto = map['fotoUrl'];
    return EntrenadorPublico(
      id: '${map['id'] ?? ''}',
      nombre: '${map['nombre'] ?? ''}',
      apellido: '${map['apellido'] ?? ''}',
      disciplina: '${map['disciplina'] ?? ''}',
      descripcion: '${map['descripcion'] ?? ''}',
      fotoUrl: foto is String && foto.isNotEmpty ? foto : null,
    );
  }
}
