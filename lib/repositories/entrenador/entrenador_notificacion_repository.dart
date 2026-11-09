import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/notificacion.dart';

abstract interface class EntrenadorNotificacionRepository {
  Stream<List<Notificacion>> notificaciones();
  Future<String?> marcarLeida(String id);
}

class FirebaseEntrenadorNotificacionAdapter
    implements EntrenadorNotificacionRepository {
  @override
  Stream<List<Notificacion>> notificaciones() {
    final uid = FirebaseServices.currentUser?.uid ?? '';
    if (uid.isEmpty) return const Stream.empty();
    return FirebaseServices.streamNotificacionesEntrenador(uid).map(
      (lista) => lista
          .map((mapa) => Notificacion.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> marcarLeida(String id) async {
    final resultado = await FirebaseServices.marcarNotificacionLeida(id: id);
    if (resultado.isSuccess) return null;
    return resultado.errorMessage ?? 'No se pudo marcar la notificación.';
  }
}
