import 'package:saman_sports/FirebaseServices.dart';

abstract interface class AdminResumenRepository {
  Future<Map<String, num>> contar();
}

class FirebaseAdminResumenAdapter implements AdminResumenRepository {
  @override
  Future<Map<String, num>> contar() => FirebaseServices.contarResumenAdmin();
}
