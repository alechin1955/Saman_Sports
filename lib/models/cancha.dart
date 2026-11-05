class Cancha {
  const Cancha({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.descripcion,
    required this.activa,
    required this.version,
  });

  final String id;
  final String nombre;
  final String ubicacion;
  final String descripcion;
  final bool activa;
  final int version;

  factory Cancha.fromMap(String id, Map<String, dynamic> map) {
    return Cancha(
      id: id,
      nombre: '${map['nombre'] ?? ''}',
      ubicacion: '${map['ubicacion'] ?? ''}',
      descripcion: '${map['descripcion'] ?? ''}',
      activa: map['activa'] != false,
      version: _entero(map['version']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'ubicacion': ubicacion,
      'descripcion': descripcion,
      'activa': activa,
    };
  }
}

int _entero(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse('$valor') ?? 0;
}
