import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/reserva_horario.dart';

abstract class AdminCalendarioRepository {
  Stream<List<Cancha>> canchas();
  Stream<List<ReservaHorario>> reservasActivas();
}

class FirebaseAdminCalendarioAdapter implements AdminCalendarioRepository {
  @override
  Stream<List<Cancha>> canchas() {
    try {
      return FirebaseServices.streamCanchas().map(
        (lista) => lista
            .map((mapa) => Cancha.fromMap('${mapa['id'] ?? ''}', mapa))
            .toList(),
      );
    } catch (_) {
      return Stream.value(const []);
    }
  }

  @override
  Stream<List<ReservaHorario>> reservasActivas() {
    try {
      return FirebaseServices.streamReservasActivas().map(
        (lista) => lista
            .map((mapa) => ReservaHorario.fromMap('${mapa['id'] ?? ''}', mapa))
            .toList(),
      );
    } catch (_) {
      return Stream.value(const []);
    }
  }
}
