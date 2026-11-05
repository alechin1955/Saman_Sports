// Esquema Firestore deportes/{id}:
// nombre, descripcion, icono ('futbol','baloncesto','tenis','voleibol',
// 'natacion','running','otro'), horario, cupos (int), inscritos (int),
// entrenadorNombre, activo (bool), entrenadorUid, canchaId, canchaNombre,
// horarios (lista de franjas).

import 'package:saman_sports/models/reserva_horario.dart';

enum EstadoCupos { disponible, pocosCupos, completo }

class Deporte {
  const Deporte({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.horario,
    required this.cupos,
    required this.inscritos,
    required this.entrenadorNombre,
    this.entrenadorUid = '',
    this.activo = true,
    this.canchaId = '',
    this.canchaNombre = '',
    this.horarios = const <FranjaHorario>[],
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final String horario;
  final int cupos;
  final int inscritos;
  final String entrenadorNombre;
  final String entrenadorUid;
  final bool activo;
  final String canchaId;
  final String canchaNombre;
  final List<FranjaHorario> horarios;

  int get disponibles => cupos - inscritos;

  EstadoCupos get estadoCupos {
    if (disponibles <= 0) return EstadoCupos.completo;
    if (cupos > 0 && disponibles / cupos <= 0.2) return EstadoCupos.pocosCupos;
    return EstadoCupos.disponible;
  }

  factory Deporte.fromMap(Map<String, dynamic> map) {
    return Deporte(
      id: '${map['id'] ?? ''}',
      nombre: '${map['nombre'] ?? ''}',
      descripcion: '${map['descripcion'] ?? ''}',
      icono: '${map['icono'] ?? 'otro'}',
      horario: '${map['horario'] ?? ''}',
      cupos: _entero(map['cupos']),
      inscritos: _entero(map['inscritos']),
      entrenadorNombre: '${map['entrenadorNombre'] ?? ''}',
      entrenadorUid: '${map['entrenadorUid'] ?? ''}',
      activo: map['activo'] != false,
      canchaId: '${map['canchaId'] ?? ''}',
      canchaNombre: '${map['canchaNombre'] ?? ''}',
      horarios: _franjas(map['horarios']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'horario': horario,
      'cupos': cupos,
      'entrenadorNombre': entrenadorNombre,
      'entrenadorUid': entrenadorUid,
      'canchaId': canchaId,
      'canchaNombre': canchaNombre,
      'horarios': horarios.map((franja) => franja.toMap()).toList(),
      'activo': activo,
    };
  }

  static List<FranjaHorario> _franjas(dynamic valor) {
    if (valor is! List) return const [];
    return valor.whereType<Map>().map((item) {
      return FranjaHorario.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse('$valor') ?? 0;
  }
}
