import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/evento.dart';

abstract interface class EventosEntrenadorRepository {
  Stream<List<Evento>> eventos();
  Future<String?> solicitar(Map<String, dynamic> datos);
}

class FirebaseEventosEntrenadorAdapter implements EventosEntrenadorRepository {
  String get _uid {
    final uid = FirebaseServices.currentUser?.uid;
    if (uid == null) throw StateError('Sesión requerida');
    return uid;
  }

  @override
  Stream<List<Evento>> eventos() {
    return FirebaseServices.streamEventosEntrenador(uid: _uid).map(
      (lista) => lista
          .map((mapa) => Evento.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) async {
    final respuesta = await FirebaseServices.solicitarEventoEntrenador(
      entrenadorUid: _uid,
      datos: datos,
    );
    if (respuesta.isSuccess) return null;
    return respuesta.errorMessage ?? 'No se pudo solicitar el evento.';
  }
}
