import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';

abstract interface class EventosEntrenadorRepository {
  Stream<List<Evento>> eventos();
  Stream<List<Cancha>> canchas();
  Stream<List<ReservaHorario>> reservasCancha(String canchaId);
  Future<String?> solicitar(Map<String, dynamic> datos);
  Future<String?> cancelar(String eventoId);
  Future<String?> editar(String eventoId, Map<String, dynamic> datos);
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
  Stream<List<Cancha>> canchas() {
    return FirebaseServices.streamCanchasEntrenador().map(
      (lista) => lista
          .map((mapa) => Cancha.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) {
    return FirebaseServices.streamReservasCanchaEntrenador(canchaId).map(
      (lista) => lista
          .map((mapa) => ReservaHorario.fromMap('${mapa['id'] ?? ''}', mapa))
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

  @override
  Future<String?> cancelar(String eventoId) async {
    final respuesta = await FirebaseServices.cancelarSolicitudEventoEntrenador(
      entrenadorUid: _uid,
      eventoId: eventoId,
    );
    if (respuesta.isSuccess) return null;
    return respuesta.errorMessage ?? AppStrings.entSolicitudNoCancelable;
  }

  @override
  Future<String?> editar(String eventoId, Map<String, dynamic> datos) async {
    final respuesta = await FirebaseServices.editarSolicitudEventoEntrenador(
      entrenadorUid: _uid,
      eventoId: eventoId,
      datos: datos,
    );
    if (respuesta.isSuccess) return null;
    return respuesta.errorMessage ?? 'No se pudo solicitar el evento.';
  }
}
