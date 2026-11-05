// Esquema Firestore pagos/{id} (se crea en el Hito 3):
// inscripcionId, estudianteUid, monto (número), idTransaccion
// (identificador de PayPal simulado), estado ('pendiente' | 'realizado'),
// fecha (Timestamp).

enum EstadoPago { pendiente, realizado }

class Pago {
  const Pago({
    required this.id,
    required this.inscripcionId,
    required this.estudianteUid,
    required this.monto,
    required this.idTransaccion,
    required this.estado,
    required this.fecha,
    this.paypalOrderId = '',
    this.fechaPago,
    this.verificado = false,
    this.verificadoPor = '',
  });

  final String id;
  final String inscripcionId;
  final String estudianteUid;
  final double monto;
  final String idTransaccion;
  final EstadoPago estado;
  final DateTime fecha;
  final String paypalOrderId;
  final DateTime? fechaPago;
  final bool verificado;
  final String verificadoPor;

  factory Pago.fromMap(Map<String, dynamic> map) {
    final monto = map['monto'];
    return Pago(
      id: '${map['id'] ?? ''}',
      inscripcionId: '${map['inscripcionId'] ?? ''}',
      estudianteUid: '${map['estudianteUid'] ?? ''}',
      monto: monto is num ? monto.toDouble() : double.tryParse('$monto') ?? 0,
      idTransaccion: '${map['idTransaccion'] ?? ''}',
      estado: EstadoPago.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoPago.pendiente,
      ),
      fecha: _fecha(map['fecha']),
      paypalOrderId: '${map['paypalOrderId'] ?? ''}',
      fechaPago: _fechaOpcional(map['fechaPago']),
      verificado: map['verificado'] == true,
      verificadoPor: '${map['verificadoPor'] ?? ''}',
    );
  }

  /// Sin id ni fecha: el id es el del documento y la fecha la pone el servidor.
  Map<String, dynamic> toMap() {
    return {
      'inscripcionId': inscripcionId,
      'estudianteUid': estudianteUid,
      'monto': monto,
      'idTransaccion': idTransaccion,
      'estado': estado.name,
      'verificado': verificado,
      if (paypalOrderId.isNotEmpty) 'paypalOrderId': paypalOrderId,
      if (fechaPago != null) 'fechaPago': fechaPago,
      if (verificadoPor.isNotEmpty) 'verificadoPor': verificadoPor,
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

  static DateTime? _fechaOpcional(dynamic valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.tryParse(valor);
    try {
      final convertida = (valor as dynamic).toDate();
      if (convertida is DateTime) return convertida;
    } catch (_) {}
    return null;
  }
}
