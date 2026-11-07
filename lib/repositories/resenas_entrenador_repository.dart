import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';

abstract interface class ResenasEntrenadorRepository {
  Future<List<Deporte>> disciplinas();
  Stream<List<Resena>> resenas();
}

class FirebaseResenasEntrenadorAdapter implements ResenasEntrenadorRepository {
  FirebaseResenasEntrenadorAdapter({EntrenadorRepository? entrenador})
    : _entrenador = entrenador ?? FirebaseEntrenadorAdapter();

  final EntrenadorRepository _entrenador;

  @override
  Future<List<Deporte>> disciplinas() => _entrenador.disciplinas();

  @override
  Stream<List<Resena>> resenas() {
    return FirebaseServices.streamResenas(limite: 100)
        .map((lista) => lista.map(Resena.fromMap).toList());
  }
}
