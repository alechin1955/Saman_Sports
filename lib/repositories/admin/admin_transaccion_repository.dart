import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/transaccion.dart';

abstract interface class AdminTransaccionRepository {
  Stream<List<Transaccion>> transacciones();
}

class FirebaseAdminTransaccionAdapter implements AdminTransaccionRepository {
  @override
  Stream<List<Transaccion>> transacciones() {
    return FirebaseServices.streamTransacciones().map(
      (lista) => lista
          .map((mapa) => Transaccion.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }
}
