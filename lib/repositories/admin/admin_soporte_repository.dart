import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/ticket_soporte.dart';

abstract interface class AdminSoporteRepository {
  Stream<List<TicketSoporte>> tickets();
  Future<String?> responder({required String id, required String respuesta});
}

class FirebaseAdminSoporteAdapter implements AdminSoporteRepository {
  @override
  Stream<List<TicketSoporte>> tickets() {
    return FirebaseServices.streamTickets().map(
      (lista) => lista
          .map((mapa) => TicketSoporte.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> responder({required String id, required String respuesta}) {
    return _texto(
      FirebaseServices.responderTicket(id: id, respuesta: respuesta),
    );
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
