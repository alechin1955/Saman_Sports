enum EstadoTicket {
  abierto('abierto'),
  resuelto('resuelto');

  const EstadoTicket(this.valor);

  final String valor;

  static EstadoTicket desde(String? texto) {
    for (final estado in EstadoTicket.values) {
      if (estado.valor == texto) return estado;
    }
    return EstadoTicket.abierto;
  }
}

class TicketSoporte {
  const TicketSoporte({
    required this.id,
    required this.asunto,
    required this.categoria,
    required this.descripcion,
    required this.autorUid,
    required this.autorNombre,
    required this.autorRol,
    required this.estado,
    required this.fecha,
    this.respuesta = '',
    this.resueltoEn,
  });

  final String id;
  final String asunto;
  final String categoria;
  final String descripcion;
  final String autorUid;
  final String autorNombre;
  final String autorRol;
  final EstadoTicket estado;
  final String respuesta;
  final DateTime fecha;
  final DateTime? resueltoEn;

  /// Nombre visible de la clave guardada en Firestore.
  String get categoriaVisible {
    return switch (categoria) {
      'cuenta' => 'Cuenta y acceso',
      'disciplinas' => 'Disciplinas',
            'pagos' => 'Pagos y solvencia',
      'asistencia' => 'Asistencia',
      'eventos' => 'Eventos',
      'otro' => 'Otro',
      _ => categoria,
    };
  }

  factory TicketSoporte.fromMap(String id, Map<String, dynamic> map) {
    return TicketSoporte(
      id: id,
      asunto: '${map['asunto'] ?? ''}',
      categoria: '${map['categoria'] ?? ''}',
      descripcion: '${map['descripcion'] ?? ''}',
      autorUid: '${map['autorUid'] ?? ''}',
      autorNombre: '${map['autorNombre'] ?? ''}',
      autorRol: '${map['autorRol'] ?? ''}',
      estado: EstadoTicket.desde(map['estado']?.toString()),
      respuesta: '${map['respuesta'] ?? ''}',
      fecha: _fecha(map['fecha']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      resueltoEn: _fecha(map['resueltoEn']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'asunto': asunto,
      'categoria': categoria,
      'descripcion': descripcion,
      'autorUid': autorUid,
      'autorNombre': autorNombre,
      'autorRol': autorRol,
      'estado': estado.valor,
      'respuesta': respuesta,
      'fecha': fecha,
      'resueltoEn': resueltoEn,
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
