// Esquema Firestore deportes/{id}:
// nombre, descripcion, icono ('futbol','baloncesto','tenis','voleibol',
// 'natacion','running','otro'), horario, cupos (int), inscritos (int),
// entrenadorNombre, activo (bool).

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
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final String horario;
  final int cupos;
  final int inscritos;
  final String entrenadorNombre;

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
    );
  }

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse('$valor') ?? 0;
  }
}
