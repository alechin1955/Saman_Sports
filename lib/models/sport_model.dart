// Patrón Modelo (MVC): Representa la entidad Deporte
class SportModel {
  final String id; // Código único
  final String name; // Nombre de la disciplina
  final int maxCapacity; // Cupo máximo
  final String schedule; // Horario de entrenamiento
  final String assignedCoach; // Entrenador Asignado
  final int enrolledCount; // Control de inscritos

  SportModel({
    required this.id,
    required this.name,
    required this.maxCapacity,
    required this.schedule,
    required this.assignedCoach,
    this.enrolledCount = 0,
  });

  factory SportModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SportModel(
      id: id,
      name: data['name'] ?? '',
      maxCapacity: data['maxCapacity'] ?? 0,
      schedule: data['schedule'] ?? '',
      assignedCoach: data['assignedCoach'] ?? 'Sin asignar',
      enrolledCount: data['enrolledCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'maxCapacity': maxCapacity,
      'schedule': schedule,
      'assignedCoach': assignedCoach,
      'enrolledCount': enrolledCount,
    };
  }
}