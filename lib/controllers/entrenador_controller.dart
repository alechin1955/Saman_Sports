import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';

class EntrenadorController extends ChangeNotifier {
  EntrenadorController({EntrenadorRepository? repository})
    : _repository = repository ?? FirestoreEntrenadorRepository();
  final EntrenadorRepository _repository;
  List<Deporte> disciplinas = [];
  List<AlumnoInscrito> alumnos = [];
  String? seleccionId;
  String busqueda = '';
  String? error;
  bool cargando = false;
  bool cargandoNomina = false;
  bool _cerrado = false;
  int _consulta = 0;

  List<AlumnoInscrito> get filtrados {
    final texto = busqueda.trim().toLowerCase();
    return alumnos
        .where(
          (a) => '${a.nombre} ${a.carnet} ${a.correo}'.toLowerCase().contains(
            texto,
          ),
        )
        .toList();
  }

  Future<void> cargar() async {
    final consulta = ++_consulta;
    cargando = true;
    cargandoNomina = false;
    error = null;
    alumnos = [];
    _avisar();
    try {
      final lista = await _repository.disciplinas().timeout(
        const Duration(seconds: 15),
      );
      if (_cerrado || consulta != _consulta) return;
      disciplinas = lista;
      seleccionId = null;
      cargando = false;
      if (lista.isNotEmpty) {
        await seleccionar(lista.first.id);
      }
    } catch (_) {
      if (_cerrado || consulta != _consulta) return;
      disciplinas = [];
      seleccionId = null;
      error = 'No se pudieron cargar tus disciplinas. Revisa la conexión y vuelve a intentar.';
    } finally {
      if (!_cerrado && consulta == _consulta) {
        cargando = false;
        _avisar();
      }
    }
  }

  Future<void> seleccionar(String id) async {
    if (!disciplinas.any((d) => d.id == id)) return;
    final consulta = ++_consulta;
    seleccionId = id;
    busqueda = '';
    alumnos = [];
    error = null;
    cargandoNomina = true;
    _avisar();
    try {
      final lista = await _repository
          .inscritos(id)
          .timeout(const Duration(seconds: 15));
      if (_cerrado || consulta != _consulta) return;
      alumnos = lista;
    } catch (_) {
      if (_cerrado || consulta != _consulta) return;
      error = 'No se pudo cargar la nómina. Vuelve a intentar.';
    } finally {
      if (!_cerrado && consulta == _consulta) {
        cargandoNomina = false;
        _avisar();
      }
    }
  }

  void buscar(String texto) {
    busqueda = texto;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _consulta++;
    super.dispose();
  }
}
