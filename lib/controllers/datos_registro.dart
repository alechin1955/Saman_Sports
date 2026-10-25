class DatosRegistro {
  const DatosRegistro({
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.carnet,
    required this.telefono,
    required this.correo,
    required this.clave,
  });

  final String nombre;
  final String apellido;
  final String cedula;
  final String carnet;
  final String telefono;
  final String correo;
  final String clave;

  Map<String, String> toMap() {
    return {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'cedula': cedula.trim(),
      'carnet': carnet.trim(),
      'telefono': telefono.trim(),
      'correo': correo.trim().toLowerCase(),
      'rol': 'estudiante',
      'creadoEn': DateTime.now().toIso8601String(),
    };
  }
}
