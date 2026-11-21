enum EstadoParticipacion { sinResponder, confirmado, rechazado }

class EventoPublico {
  const EventoPublico({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.deporteId,
    required this.deporteNombre,
    required this.canchaNombre,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.descripcion,
  });

  final String id;
  final String titulo;
  final String tipo;
  final String deporteId;
  final String deporteNombre;
  final String canchaNombre;
  final String fecha;
  final int horaInicio;
  final int horaFin;
  final String descripcion;

  DateTime? get dia => DateTime.tryParse(fecha);

  factory EventoPublico.fromMap(String id, Map<String, dynamic> map) {
    return EventoPublico(
      id: id,
      titulo: '${map['titulo'] ?? ''}',
      tipo: '${map['tipo'] ?? ''}',
      deporteId: '${map['deporteId'] ?? ''}',
      deporteNombre: '${map['deporteNombre'] ?? ''}',
      canchaNombre: '${map['canchaNombre'] ?? ''}',
      fecha: '${map['fecha'] ?? ''}',
      horaInicio: int.tryParse('${map['horaInicio'] ?? 0}') ?? 0,
      horaFin: int.tryParse('${map['horaFin'] ?? 0}') ?? 0,
      descripcion: '${map['descripcion'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'tipo': tipo,
      'deporteId': deporteId,
      'deporteNombre': deporteNombre,
      'canchaNombre': canchaNombre,
      'fecha': fecha,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'descripcion': descripcion,
    };
  }
}
