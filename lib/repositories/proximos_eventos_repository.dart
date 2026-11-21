import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/evento_publico.dart';

abstract interface class ProximosEventosRepository {
  Stream<List<EventoPublico>> publicos({required String desdeFecha, int limite = 20});
  Stream<List<Map<String, dynamic>>> inscripciones(String uid);
  Stream<String> participacion({required String eventoId, required String uid});
  Stream<List<Map<String, dynamic>>> participantes({required String eventoId});
  Future<String?> responder({
    required String eventoId,
    required bool asistira,
    String? notificacionId,
  });
}

class FirebaseProximosEventosAdapter implements ProximosEventosRepository {
  @override
  Stream<List<EventoPublico>> publicos({
    required String desdeFecha,
    int limite = 20,
  }) {
    try {
      return FirebaseServices.streamEventosPublicos(
        desdeFecha: desdeFecha,
        limite: limite,
      ).map(
        (lista) => lista
            .map((mapa) => EventoPublico.fromMap('${mapa['id'] ?? ''}', mapa))
            .toList(),
      );
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> inscripciones(String uid) {
    try {
      return FirebaseServices.streamMisInscripciones(estudianteUid: uid);
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Stream<String> participacion({required String eventoId, required String uid}) {
    try {
      return FirebaseServices.streamParticipacion(eventoId: eventoId, uid: uid);
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> participantes({required String eventoId}) {
    try {
      return FirebaseServices.streamParticipantesEvento(eventoId: eventoId);
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<String?> responder({
    required String eventoId,
    required bool asistira,
    String? notificacionId,
  }) async {
    try {
      await FirebaseServices.responderParticipacionEvento(
        eventoId: eventoId,
        asistira: asistira,
        notificacionId: notificacionId,
      );
      return null;
    } catch (e) {
      return '$e';
    }
  }
}
