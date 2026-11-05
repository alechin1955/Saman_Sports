import 'package:flutter/foundation.dart';
import 'package:saman_sports/repositories/admin/admin_resumen_repository.dart';

class AdminResumenController extends ChangeNotifier {
  AdminResumenController({AdminResumenRepository? repository})
    : _repository = repository ?? FirebaseAdminResumenAdapter();

  final AdminResumenRepository _repository;
  Map<String, num> conteos = {};
  bool cargando = false;
  String? error;
  bool _cerrado = false;

  Future<void> cargar() => _leer();

  Future<void> refrescar() => _leer();

  Future<void> _leer() async {
    if (_cerrado) return;
    cargando = true;
    error = null;
    _avisar();
    try {
      conteos = await _repository.contar();
    } catch (_) {
      if (_cerrado) return;
      error = 'No se pudo cargar el resumen.';
      conteos = {};
    } finally {
      if (!_cerrado) {
        cargando = false;
        _avisar();
      }
    }
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
