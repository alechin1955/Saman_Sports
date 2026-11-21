import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';

abstract interface class PerfilEntrenadorRepository {
  Future<PerfilEntrenador> cargar();
}

abstract interface class PerfilEntrenadorEdicionRepository {
  Future<String?> guardar({
    required String uid,
    required String telefono,
    required String biografia,
    required int anosExperiencia,
    required List<String> certificaciones,
  });
}

class FirebasePerfilEntrenadorEdicionAdapter
    implements PerfilEntrenadorEdicionRepository {
  @override
  Future<String?> guardar({
    required String uid,
    required String telefono,
    required String biografia,
    required int anosExperiencia,
    required List<String> certificaciones,
  }) async {
    final respuesta = await FirebaseServices.actualizarPerfilEntrenador(
      uid: uid,
      telefono: telefono,
      biografia: biografia,
      anosExperiencia: anosExperiencia,
      certificaciones: certificaciones,
    );
    if (respuesta.isSuccess) return null;
    return respuesta.errorMessage ?? 'No se pudo guardar el perfil.';
  }
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
