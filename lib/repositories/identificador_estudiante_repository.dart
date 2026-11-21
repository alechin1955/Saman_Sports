import 'package:saman_sports/FirebaseServices.dart';

abstract interface class IdentificadorEstudianteRepository {
  Future<void> asegurar(String uid);
}

class FirebaseIdentificadorEstudianteAdapter
    implements IdentificadorEstudianteRepository {
  @override
  Future<void> asegurar(String uid) {
    return FirebaseServices.asegurarIdentificadoresEstudiante(uid: uid);
  }
}
