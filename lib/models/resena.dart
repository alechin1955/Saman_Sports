// Esquema Firestore resenas/{id}:
// autorUid (uid del estudiante), autorNombre, disciplina, deporteId,
// estrellas (1–5), comentario, fecha (Timestamp), visible (bool).
// Las reseñas las crean los estudiantes desde su panel. El Home solo las lee.
// visible permite que el admin oculte reseñas inapropiadas.

class Resena {
  const Resena({
    required this.id,
    required this.autorUid,
    required this.autorNombre,
    required this.disciplina,
    required this.deporteId,
    required this.estrellas,
    required this.comentario,
    required this.fecha,
  });

  final String id;
  final String autorUid;
  final String autorNombre;
  final String disciplina;
  final String deporteId;
  final int estrellas;
  final String comentario;
  final DateTime fecha;

  factory Resena.fromMap(Map<String, dynamic> map) {
    final valor = map['estrellas'];
    final estrellas = valor is int ? valor : int.tryParse('$valor') ?? 1;
    return Resena(
      id: '${map['id'] ?? ''}',
      autorUid: '${map['autorUid'] ?? ''}',
      autorNombre: '${map['autorNombre'] ?? ''}',
      disciplina: '${map['disciplina'] ?? ''}',
      deporteId: '${map['deporteId'] ?? ''}',
      estrellas: estrellas.clamp(1, 5),
      comentario: '${map['comentario'] ?? ''}',
      fecha: _fecha(map['fecha']),
    );
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
