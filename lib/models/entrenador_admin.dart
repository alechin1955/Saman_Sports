class EntrenadorAdmin {
  const EntrenadorAdmin({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.disciplina,
    required this.descripcion,
    required this.activo,
    required this.especialidad,
    required this.anosExperiencia,
    required this.correo,
    required this.cedula,
    required this.telefono,
    this.fotoUrl,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String disciplina;
  final String descripcion;
  final String? fotoUrl;
  final bool activo;
  final String especialidad;
  final int anosExperiencia;
  final String correo;
  final String cedula;
  final String telefono;

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory EntrenadorAdmin.desdeMapas(
    String uid,
    Map<dynamic, dynamic> publico, [
    Map<dynamic, dynamic>? privado,
  ]) {
    final foto = publico['fotoUrl'];
    final experiencia = publico['anosExperiencia'];
    return EntrenadorAdmin(
      uid: uid,
      nombre: '${publico['nombre'] ?? privado?['nombre'] ?? ''}',
      apellido: '${publico['apellido'] ?? privado?['apellido'] ?? ''}',
      disciplina: '${publico['disciplina'] ?? ''}',
      descripcion: '${publico['descripcion'] ?? ''}',
      fotoUrl: foto is String && foto.isNotEmpty ? foto : null,
      activo: publico['activo'] != false,
      especialidad: '${publico['especialidad'] ?? ''}',
      anosExperiencia: experiencia is num ? experiencia.toInt() : 0,
      correo: '${privado?['correo'] ?? ''}',
      cedula: '${privado?['cedula'] ?? ''}',
      telefono: '${privado?['telefono'] ?? ''}',
    );
  }

  Map<String, dynamic> toMapPublico() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'disciplina': disciplina,
      'descripcion': descripcion,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      'activo': activo,
      'especialidad': especialidad,
      'anosExperiencia': anosExperiencia,
    };
  }

  Map<String, dynamic> toMapPrivado() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'telefono': telefono,
      'correo': correo,
      'rol': 'entrenador',
    };
  }
}
