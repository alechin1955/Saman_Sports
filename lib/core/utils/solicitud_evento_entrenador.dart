import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/reserva_horario.dart';

/// Construye la única forma de evento que puede solicitar un entrenador.
/// Los campos de autorización se derivan de la sesión y de la disciplina,
/// nunca del mapa recibido desde la interfaz.
Map<String, dynamic> construirSolicitudEventoEntrenador({
  required Map<String, dynamic> datos,
  required String entrenadorUid,
  required Map<String, dynamic> deporte,
  required DateTime ahora,
}) {
  final titulo = '${datos['titulo'] ?? ''}'.trim();
  final deporteId = '${datos['deporteId'] ?? ''}'.trim();
  final fecha = '${datos['fecha'] ?? ''}'.trim();
  final ubicacion = '${datos['ubicacion'] ?? ''}'.trim();
  final horaInicio = _entero(datos['horaInicio']);
  final horaFin = _entero(datos['horaFin']);
  final capacidad = _entero(datos['capacidad']);
  final descripcion = '${datos['descripcion'] ?? ''}'.trim();

  if (titulo.isEmpty) throw StateError('El nombre es obligatorio.');
  if (deporteId.isEmpty) throw StateError('Elige una disciplina.');
  if (ubicacion.isEmpty) throw StateError('La ubicación es obligatoria.');
  if (capacidad <= 0) {
    throw StateError('La capacidad debe ser mayor que cero.');
  }
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) {
    throw StateError('La fecha del evento no es válida.');
  }
  final dia = DateTime.tryParse(fecha);
  final fechaNormalizada = dia == null
      ? null
      : '${dia.year.toString().padLeft(4, '0')}-'
            '${dia.month.toString().padLeft(2, '0')}-'
            '${dia.day.toString().padLeft(2, '0')}';
  if (dia == null || fechaNormalizada != fecha) {
    throw StateError('La fecha del evento no es válida.');
  }
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final normalizada = DateTime(dia.year, dia.month, dia.day);
  if (normalizada.isBefore(hoy)) {
    throw StateError('La fecha del evento no puede estar en el pasado.');
  }
  final errorFranja = validarFranja(
    FranjaHorario(
      dia: normalizada.weekday,
      horaInicio: horaInicio,
      horaFin: horaFin,
    ),
  );
  if (errorFranja != null) throw StateError(errorFranja);
  if ('${deporte['id'] ?? ''}' != deporteId ||
      deporte['entrenadorUid'] != entrenadorUid ||
      deporte['activo'] != true) {
    throw StateError('La disciplina no está asignada al entrenador.');
  }

  return {
    'titulo': titulo,
    'tipo': 'evento',
    'deporteId': deporteId,
    'deporteNombre': '${deporte['nombre'] ?? ''}',
    'canchaId': '${deporte['canchaId'] ?? ''}',
    'canchaNombre': ubicacion,
    'ubicacion': ubicacion,
    'fecha': fecha,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'capacidad': capacidad,
    'descripcion': descripcion,
    'estado': 'pendiente',
    'creadoPorUid': entrenadorUid,
  };
}

int _entero(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse('$valor') ?? 0;
}
