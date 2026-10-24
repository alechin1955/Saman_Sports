// Esquema Firestore inscripciones/{id} (se crea en el Hito 3):
// estudianteUid, deporteId, deporteNombre,
// estado ('pendiente' | 'confirmada' | 'cancelada'), fecha (Timestamp),
// pagoId (opcional; se llena cuando el pago se realiza).

enum EstadoInscripcion { pendiente, confirmada, cancelada }

class Inscripcion {
  const Inscripcion({
    required this.id,
    required this.estudianteUid,
    required this.deporteId,
    required this.deporteNombre,
    required this.estado,
    required this.fecha,
    this.pagoId,
  });

  final String id;
  final String estudianteUid;
  final String deporteId;
  final String deporteNombre;
  final EstadoInscripcion estado;
  final DateTime fecha;
  final String? pagoId;

  /// Una inscripción cancelada ya no ocupa cupo.
  bool get activa => estado != EstadoInscripcion.cancelada;

  factory Inscripcion.fromMap(Map<String, dynamic> map) {
    final pago = map['pagoId'];
    return Inscripcion(
      id: '${map['id'] ?? ''}',
      estudianteUid: '${map['estudianteUid'] ?? ''}',
      deporteId: '${map['deporteId'] ?? ''}',
      deporteNombre: '${map['deporteNombre'] ?? ''}',
      estado: EstadoInscripcion.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoInscripcion.pendiente,
      ),
      fecha: _fecha(map['fecha']),
      pagoId: pago is String && pago.isNotEmpty ? pago : null,
    );
  }

  /// Sin id ni fecha: el id es el del documento y la fecha la pone el servidor.
  Map<String, dynamic> toMap() {
    return {
      'estudianteUid': estudianteUid,
      'deporteId': deporteId,
      'deporteNombre': deporteNombre,
      'estado': estado.name,
      if (pagoId != null) 'pagoId': pagoId,
    };
  }

  static DateTime _fecha(dynamic valor) {
    if (valor is DateTime) return valor;
    try {
      final convertida = (valor as dynamic)?.toDate();
      if (convertida is DateTime) return convertida;
    } catch (_) {}
    return DateTime.now();
  }
}
