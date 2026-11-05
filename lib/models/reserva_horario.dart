enum TipoReserva {
  deporte('deporte'),
  evento('evento');

  const TipoReserva(this.valor);

  final String valor;

  static TipoReserva desde(String? texto) {
    for (final tipo in TipoReserva.values) {
      if (tipo.valor == texto) return tipo;
    }
    return TipoReserva.deporte;
  }
}

class FranjaHorario {
  const FranjaHorario({
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
  });

  final int dia;
  final int horaInicio;
  final int horaFin;

  factory FranjaHorario.fromMap(Map<String, dynamic> map) {
    return FranjaHorario(
      dia: _entero(map['dia']),
      horaInicio: _entero(map['horaInicio']),
      horaFin: _entero(map['horaFin']),
    );
  }

  Map<String, int> toMap() {
    return {'dia': dia, 'horaInicio': horaInicio, 'horaFin': horaFin};
  }

  FranjaHorario copyWith({int? dia, int? horaInicio, int? horaFin}) {
    return FranjaHorario(
      dia: dia ?? this.dia,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FranjaHorario &&
        other.dia == dia &&
        other.horaInicio == horaInicio &&
        other.horaFin == horaFin;
  }

  @override
  int get hashCode => Object.hash(dia, horaInicio, horaFin);
}

class ReservaHorario {
  const ReservaHorario({
    required this.id,
    required this.canchaId,
    required this.canchaNombre,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.tipo,
    required this.refId,
    required this.refNombre,
    required this.activa,
    this.fecha,
  });

  final String id;
  final String canchaId;
  final String canchaNombre;
  final int dia;
  final int horaInicio;
  final int horaFin;
  final String? fecha;
  final TipoReserva tipo;
  final String refId;
  final String refNombre;
  final bool activa;

  FranjaHorario get franja =>
      FranjaHorario(dia: dia, horaInicio: horaInicio, horaFin: horaFin);

  factory ReservaHorario.fromMap(String id, Map<String, dynamic> map) {
    final fecha = map['fecha'];
    return ReservaHorario(
      id: id,
      canchaId: '${map['canchaId'] ?? ''}',
      canchaNombre: '${map['canchaNombre'] ?? ''}',
      dia: _entero(map['dia']),
      horaInicio: _entero(map['horaInicio']),
      horaFin: _entero(map['horaFin']),
      fecha: fecha is String && fecha.isNotEmpty ? fecha : null,
      tipo: TipoReserva.desde(map['tipo']?.toString()),
      refId: '${map['refId'] ?? ''}',
      refNombre: '${map['refNombre'] ?? ''}',
      activa: map['activa'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canchaId': canchaId,
      'canchaNombre': canchaNombre,
      'dia': dia,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'fecha': fecha,
      'tipo': tipo.valor,
      'refId': refId,
      'refNombre': refNombre,
      'activa': activa,
    };
  }
}

int _entero(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse('$valor') ?? 0;
}
