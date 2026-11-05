class ConfiguracionPagos {
  const ConfiguracionPagos({
    required this.periodo,
    required this.fechaInicio,
    required this.fechaCorte,
    required this.monto,
  });

  final String periodo;
  final DateTime fechaInicio;
  final DateTime fechaCorte;
  final double monto;

  factory ConfiguracionPagos.fromMap(Map<String, dynamic> map) {
    final monto = map['monto'];
    return ConfiguracionPagos(
      periodo: '${map['periodo'] ?? ''}',
      fechaInicio:
          _fecha(map['fechaInicio']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      fechaCorte:
          _fecha(map['fechaCorte']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      monto: monto is num ? monto.toDouble() : double.tryParse('$monto') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'periodo': periodo,
      'fechaInicio': fechaInicio,
      'fechaCorte': fechaCorte,
      'monto': monto,
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
