import 'package:flutter/foundation.dart';
import 'package:saman_sports/repositories/admin/admin_resumen_repository.dart';

class AdminResumenController extends ChangeNotifier {
  AdminResumenController({AdminResumenRepository? repository})
    : _repository = repository ?? FirebaseAdminResumenAdapter();

  final AdminResumenRepository _repository;
  Map<String, num> conteos = {};
  List<Map<String, dynamic>> deportesPopulares = [];
  List<Map<String, dynamic>> inscripcionesPorMes = [];
  double resenasPromedio = 0;
  int resenasCantidad = 0;
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
      final graficos = await _repository.graficos();
      deportesPopulares = _mapas(graficos['deportesPopulares']);
      inscripcionesPorMes = _mapas(graficos['inscripcionesPorMes']);
      resenasCantidad = (graficos['resenasCantidad'] as num?)?.toInt() ?? 0;
      resenasPromedio = (graficos['resenasPromedio'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      if (_cerrado) return;
      error = 'No se pudo cargar el resumen.';
      conteos = {};
      deportesPopulares = [];
      inscripcionesPorMes = [];
      resenasCantidad = 0;
      resenasPromedio = 0;
    } finally {
      if (!_cerrado) {
        cargando = false;
        _avisar();
      }
    }
  }

  List<Map<String, dynamic>> _mapas(dynamic valor) {
    if (valor is! List) return [];
    return [
      for (final item in valor)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
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
