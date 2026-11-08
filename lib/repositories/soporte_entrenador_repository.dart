import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/ticket_soporte.dart';

abstract interface class SoporteEntrenadorRepository {
  Stream<List<TicketSoporte>> tickets();

  Future<String?> crear({
    required String categoria,
    required String asunto,
    required String descripcion,
  });
}

class FirebaseSoporteEntrenadorAdapter implements SoporteEntrenadorRepository {
  String get _uid {
    final usuario = FirebaseServices.currentUser;
    if (usuario == null) throw StateError('Sesión requerida');
    return usuario.uid;
  }

  @override
  Stream<List<TicketSoporte>> tickets() {
    final uid = _uid;
    return FirebaseServices.streamTicketsEntrenador(entrenadorUid: uid).map(
      (lista) => lista
          .map((mapa) => TicketSoporte.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> crear({
    required String categoria,
    required String asunto,
    required String descripcion,
  }) async {
    final respuesta = await FirebaseServices.crearTicketEntrenador(
      entrenadorUid: _uid,
      categoria: categoria,
      asunto: asunto,
      descripcion: descripcion,
    );
    if (respuesta.isSuccess) return null;
    return respuesta.errorMessage ??
        'No se pudo enviar la solicitud. Intenta nuevamente.';
  }
}
