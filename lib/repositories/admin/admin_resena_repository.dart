import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/resena.dart';

abstract interface class AdminResenaRepository {
  Stream<List<({Resena resena, bool visible})>> resenas();
  Future<String?> cambiarVisibilidad({
    required String id,
    required bool visible,
  });
}

class FirebaseAdminResenaAdapter implements AdminResenaRepository {
  @override
  Stream<List<({Resena resena, bool visible})>> resenas() {
    return FirebaseServices.streamResenasAdmin().map(
      (lista) => lista
          .map(
            (mapa) => (
              resena: Resena.fromMap(mapa),
              visible: mapa['visible'] != false,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<String?> cambiarVisibilidad({
    required String id,
    required bool visible,
  }) {
    return _texto(
      FirebaseServices.cambiarVisibilidadResena(id: id, visible: visible),
    );
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
