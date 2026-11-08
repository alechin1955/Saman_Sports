import 'package:saman_sports/FirebaseServices.dart';

abstract interface class AdminResumenRepository {
  Future<Map<String, num>> contar();
  Future<Map<String, dynamic>> graficos();
}

class FirebaseAdminResumenAdapter implements AdminResumenRepository {
  @override
  Future<Map<String, num>> contar() => FirebaseServices.contarResumenAdmin();

  @override
  Future<Map<String, dynamic>> graficos() =>
      FirebaseServices.resumenGraficosAdmin();
}
