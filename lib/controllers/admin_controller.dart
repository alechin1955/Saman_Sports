// Patrón Controlador (MVC): Lógica de negocio del Administrador
import '../models/sport_model.dart';
import '../repositories/sport_repository.dart';

class AdminController {
  final _repository = SportRepository();

  Stream<List<SportModel>> get sportsStream => _repository.getSportsStream();

  Future<void> createSport(String name, int maxCapacity, String schedule, String assignedCoach) {
    return _repository.addSport(SportModel(
      id: '',
      name: name,
      maxCapacity: maxCapacity,
      schedule: schedule,
      assignedCoach: assignedCoach,
      enrolledCount: 0,
    ));
  }

  Future<void> updateSport(String id, String name, int maxCapacity, String schedule, String assignedCoach) {
    return _repository.updateSport(id, {
      'name': name,
      'maxCapacity': maxCapacity,
      'schedule': schedule,
      'assignedCoach': assignedCoach,
    });
  }

  Future<void> deleteSport(String id) => _repository.deleteSport(id);
}