import 'dart:async';
import '../models/entrenador_model.dart';
import '../repositories/entrenador_repository.dart';

class EntrenadorController {
  final EntrenadorRepository _repository = EntrenadorRepository();

  Future<bool> createEntrenador({
    required String cedula,
    required String nombre,
    required String correo,
    required String especialidad,
    required int anosExperiencia,
  }) async {
    try {
      final newEntrenador = EntrenadorModel(
        cedula: cedula,
        nombre: nombre,
        correo: correo,
        especialidad: especialidad,
        anosExperiencia: anosExperiencia,
      );
      
      // Aplicamos el Timeout de 15 segundos para evitar pantallas de carga infinitas
      await _repository.createEntrenador(newEntrenador).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Firebase tardó demasiado en responder.');
        },
      );
      
      return true;
    } catch (e) {
      print('=== ERROR EN CONTROLADOR ENTRENADOR ===');
      print(e.toString());
      return false;
    }
  }

  Future<bool> updateEntrenador(EntrenadorModel entrenador) async {
    try {
      await _repository.updateEntrenador(entrenador).timeout(const Duration(seconds: 15));
      return true;
    } catch (e) {
      print('Error al actualizar entrenador: $e');
      return false;
    }
  }

  Future<bool> deleteEntrenador(String id) async {
    try {
      await _repository.deleteEntrenador(id).timeout(const Duration(seconds: 15));
      return true;
    } catch (e) {
      print('Error al eliminar entrenador: $e');
      return false;
    }
  }
}