import 'package:saman_sports/models/reserva_horario.dart';

enum TipoEvento {
  partido('partido'),
  evento('evento');

  const TipoEvento(this.valor);

  final String valor;

  static TipoEvento desde(String? texto) {
    for (final tipo in TipoEvento.values) {
      if (tipo.valor == texto) return tipo;
    }
    return TipoEvento.evento;
  }
}

enum EstadoEvento {
  pendiente('pendiente'),
  aprobado('aprobado'),
  rechazado('rechazado'),
  cancelado('cancelado');

  const EstadoEvento(this.valor);

  final String valor;

  static EstadoEvento desde(String? texto) {
    for (final estado in EstadoEvento.values) {
      if (estado.valor == texto) return estado;
    }
    return EstadoEvento.pendiente;
  }
}

class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.canchaId,
    required this.canchaNombre,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.descripcion,
    required this.estado,
    required this.creadoPorUid,
    this.deporteId,
    this.deporteNombre,
    this.creadoEn,
    this.reemplazaPractica = false,
  });

  final String id;
  final String titulo;
  final TipoEvento tipo;
  final String? deporteId;
  final String? deporteNombre;
  final String canchaId;
  final String canchaNombre;
  final String fecha;
  final int horaInicio;
  final int horaFin;
  final String descripcion;
  final EstadoEvento estado;
  final String creadoPorUid;
  final DateTime? creadoEn;
  final bool reemplazaPractica;

  FranjaHorario get franja => FranjaHorario(
    dia: DateTime.parse(fecha).weekday,
    horaInicio: horaInicio,
    horaFin: horaFin,
  );

  factory Evento.fromMap(String id, Map<String, dynamic> map) {
    return Evento(
      id: id,
      titulo: '${map['titulo'] ?? ''}',
      tipo: TipoEvento.desde(map['tipo']?.toString()),
      deporteId: _texto(map['deporteId']),
      deporteNombre: _texto(map['deporteNombre']),
      canchaId: '${map['canchaId'] ?? ''}',
      canchaNombre: '${map['canchaNombre'] ?? ''}',
      fecha: '${map['fecha'] ?? ''}',
      horaInicio: _entero(map['horaInicio']),
      horaFin: _entero(map['horaFin']),
      descripcion: '${map['descripcion'] ?? ''}',
      estado: EstadoEvento.desde(map['estado']?.toString()),
      creadoPorUid: '${map['creadoPorUid'] ?? map['creadoPor'] ?? ''}',
      creadoEn: _fecha(map['creadoEn']),
      reemplazaPractica: map['reemplazaPractica'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'tipo': tipo.valor,
      'deporteId': deporteId,
      'deporteNombre': deporteNombre,
      'canchaId': canchaId,
      'canchaNombre': canchaNombre,
      'fecha': fecha,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'descripcion': descripcion,
      'estado': estado.valor,
      'creadoPorUid': creadoPorUid,
      'creadoEn': creadoEn,
      'reemplazaPractica': reemplazaPractica,
    };
  }
}

String? _texto(dynamic valor) {
  if (valor is String && valor.isNotEmpty) return valor;
  return null;
}

int _entero(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse('$valor') ?? 0;
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
