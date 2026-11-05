class Transaccion {
  const Transaccion({
    required this.id,
    required this.fecha,
    required this.usuarioUid,
    required this.usuarioNombre,
    required this.rol,
    required this.accion,
    required this.modulo,
    required this.descripcion,
  });

  final String id;
  final DateTime fecha;
  final String usuarioUid;
  final String usuarioNombre;
  final String rol;
  final String accion;
  final String modulo;
  final String descripcion;

  factory Transaccion.fromMap(String id, Map<String, dynamic> map) {
    return Transaccion(
      id: id,
      fecha: _fecha(map['fecha']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      usuarioUid: '${map['usuarioUid'] ?? ''}',
      usuarioNombre: '${map['usuarioNombre'] ?? ''}',
      rol: '${map['rol'] ?? ''}',
      accion: '${map['accion'] ?? ''}',
      modulo: '${map['modulo'] ?? ''}',
      descripcion: '${map['descripcion'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'usuarioUid': usuarioUid,
      'usuarioNombre': usuarioNombre,
      'rol': rol,
      'accion': accion,
      'modulo': modulo,
      'descripcion': descripcion,
    };
  }
}

DateTime? _fecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  if (valor is String) return DateTime.tryParse(valor);
  try {
    final convertida = (valor as dynamic).toDate();
    if (convertida is DateTime) return convertida;
  } catch (_) {}
  return null;
}
