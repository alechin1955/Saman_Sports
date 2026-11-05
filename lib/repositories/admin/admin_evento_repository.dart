import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';

abstract interface class AdminEventoRepository {
  Stream<List<Evento>> eventos();
  Stream<List<Cancha>> canchas();
  Stream<List<ReservaHorario>> reservasCancha(String canchaId);
  Future<String?> crearEvento({
    required Map<String, dynamic> datos,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
  });
  Future<String?> actualizarEvento({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    String? fecha,
    int? horaInicio,
    int? horaFin,
  });
  Future<String?> cambiarEstadoEvento({
    required String id,
    required String estado,
  });
}

class FirebaseAdminEventoAdapter implements AdminEventoRepository {
  @override
  Stream<List<Evento>> eventos() {
    return FirebaseServices.streamEventos().map(
      (lista) => lista
          .map((mapa) => Evento.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Stream<List<Cancha>> canchas() {
    return FirebaseServices.streamCanchas().map(
      (lista) => lista
          .map((mapa) => Cancha.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) {
    return FirebaseServices.streamReservasCancha(canchaId).map(
      (lista) => lista
          .map((mapa) => ReservaHorario.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> crearEvento({
    required Map<String, dynamic> datos,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
  }) {
    return _texto(
      FirebaseServices.crearEvento(
        datos: datos,
        canchaId: canchaId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
      ),
    );
  }

  @override
  Future<String?> actualizarEvento({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    String? fecha,
    int? horaInicio,
    int? horaFin,
  }) {
    return _texto(
      FirebaseServices.actualizarEvento(
        id: id,
        datos: datos,
        canchaId: canchaId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
      ),
    );
  }

  @override
  Future<String?> cambiarEstadoEvento({
    required String id,
    required String estado,
  }) {
    return _texto(FirebaseServices.cambiarEstadoEvento(id: id, estado: estado));
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
