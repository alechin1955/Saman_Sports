import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';

abstract interface class PerfilEntrenadorRepository {
  Future<PerfilEntrenador> cargar();
}

class FirebasePerfilEntrenadorAdapter implements PerfilEntrenadorRepository {
  @override
  Future<PerfilEntrenador> cargar() async {
    final uid = FirebaseServices.currentUser?.uid;
    if (uid == null) throw StateError('Sesión requerida');
    final datos = await FirebaseServices.getPerfilEntrenador(uid: uid);
    if (datos == null) throw StateError('Perfil no encontrado');
    return PerfilEntrenador.fromMap(uid, datos);
  }
}
