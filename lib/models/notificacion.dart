class Notificacion {
  const Notificacion({
    required this.id,
    required this.destinatarioUid,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.periodo,
    required this.leida,
    required this.fecha,
  });

  final String id;
  final String destinatarioUid;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String periodo;
  final bool leida;
  final DateTime fecha;

  factory Notificacion.fromMap(String id, Map<String, dynamic> map) {
    return Notificacion(
      id: id,
      destinatarioUid: '${map['destinatarioUid'] ?? ''}',
      tipo: '${map['tipo'] ?? ''}',
      titulo: '${map['titulo'] ?? ''}',
      mensaje: '${map['mensaje'] ?? ''}',
      periodo: '${map['periodo'] ?? ''}',
      leida: map['leida'] == true,
      fecha: _fecha(map['fecha']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'destinatarioUid': destinatarioUid,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'periodo': periodo,
      'leida': leida,
      'fecha': fecha,
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
