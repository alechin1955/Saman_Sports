import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/notificacion.dart';

abstract interface class NotificacionesRepository {
  Stream<String?> uidSesion();
  Future<String?> rolDe(String uid);
  Stream<List<Notificacion>> propias(String uid);
  Stream<List<Notificacion>> bandejaAdmin();
  Future<String?> marcarLeida(Notificacion aviso);
  Future<String?> responderParticipacion(Notificacion aviso, bool asistira);
}

class FirebaseNotificacionesAdapter implements NotificacionesRepository {
  @override
  Stream<String?> uidSesion() {
    try {
      return FirebaseServices.authStateChanges().map((usuario) => usuario?.uid);
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<String?> rolDe(String uid) async {
    final datos = await FirebaseServices.getUserData(uid: uid);
    return datos == null ? null : '${datos['rol'] ?? ''}';
  }

  @override
  Stream<List<Notificacion>> propias(String uid) {
    return _lista(() => FirebaseServices.streamNotificacionesDe(uid));
  }

  @override
  Stream<List<Notificacion>> bandejaAdmin() {
    return _lista(FirebaseServices.streamNotificacionesAdmin);
  }

  @override
  Future<String?> marcarLeida(Notificacion aviso) async {
    try {
      if (aviso.destinatarioRol == 'administrador') {
        await FirebaseServices.marcarAvisoAdminLeido(id: aviso.id);
      } else {
        final respuesta = await FirebaseServices.marcarNotificacionLeida(
          id: aviso.id,
        );
        if (!respuesta.isSuccess) return respuesta.errorMessage;
      }
      return null;
    } catch (e) {
      return '$e';
    }
  }

  @override
  Future<String?> responderParticipacion(Notificacion aviso, bool asistira) async {
    try {
      await FirebaseServices.responderParticipacionEvento(
        eventoId: aviso.eventoId,
        asistira: asistira,
        notificacionId: aviso.id,
      );
      return null;
    } catch (e) {
      return '$e';
    }
  }

  Stream<List<Notificacion>> _lista(
    Stream<List<Map<String, dynamic>>> Function() origen,
  ) {
    try {
      return origen().map(_mapear);
    } catch (_) {
      return const Stream.empty();
    }
  }

  List<Notificacion> _mapear(List<Map<String, dynamic>> lista) {
    return lista
        .map((mapa) => Notificacion.fromMap('${mapa['id'] ?? ''}', mapa))
        .toList();
  }
}
