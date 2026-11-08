class PerfilEntrenador {
  const PerfilEntrenador({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.disciplina,
    required this.especialidad,
    required this.biografia,
    required this.anosExperiencia,
    required this.certificaciones,
    required this.activo,
    this.fotoUrl,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String disciplina;
  final String especialidad;
  final String biografia;
  final int anosExperiencia;
  final List<String> certificaciones;
  final bool activo;
  final String? fotoUrl;

  String get nombreCompleto => '$nombre $apellido'.trim();

  String get iniciales {
    final partes = nombreCompleto
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'E';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  factory PerfilEntrenador.fromMap(String uid, Map<String, dynamic> map) {
    final certificaciones = map['certificaciones'];
    final experiencia = map['anosExperiencia'] ?? map['aniosExperiencia'];
    final foto = map['fotoUrl'];
    return PerfilEntrenador(
      uid: uid,
      nombre: '${map['nombre'] ?? ''}',
      apellido: '${map['apellido'] ?? ''}',
      correo: '${map['correo'] ?? ''}',
      telefono: '${map['telefono'] ?? ''}',
      disciplina: '${map['disciplina'] ?? ''}',
      especialidad: '${map['especialidad'] ?? ''}',
      biografia: '${map['biografia'] ?? map['descripcion'] ?? ''}',
      anosExperiencia: experiencia is num
          ? experiencia.toInt()
          : int.tryParse('$experiencia') ?? 0,
      certificaciones: certificaciones is List
          ? certificaciones.map((item) => '$item').toList(growable: false)
          : const [],
      activo: map['activo'] != false && map['estado'] != 'inactivo',
      fotoUrl: foto is String && foto.trim().isNotEmpty ? foto : null,
    );
  }
}
