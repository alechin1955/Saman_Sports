import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/constants/datos_ejemplo.dart';
import 'package:saman_sports/models/deporte.dart';

/// Origen de los deportes en vivo (por defecto, FirebaseServices.streamDeportes).
typedef OrigenDeportes = Stream<List<Map<String, dynamic>>> Function();

/// Controlador de "Explorar deportes" (Observer: sujeto concreto).
///
/// Escucha el catálogo en tiempo real y aplica la búsqueda y los filtros
/// sobre la lista ya recibida, sin hacer consultas nuevas a Firebase.
class ExplorarDeportesController extends ChangeNotifier {
  ExplorarDeportesController({OrigenDeportes? origen})
    : _origen = origen ?? FirebaseServices.streamDeportes;

  /// Días que se pueden filtrar (tal como aparecen en el horario).
  static const List<String> dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  final OrigenDeportes _origen;

  List<Deporte> deportes = [];
  bool cargando = true;
  bool usandoEjemplo = false;
  String? error;

  String busqueda = '';
  bool soloConCupos = false;
  String? dia;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  Timer? _espera;

  /// Se suscribe al catálogo. Espera máximo 5 s por el primer dato.
  void iniciar() {
    _sub?.cancel();
    _espera?.cancel();
    cargando = true;
    error = null;
    notifyListeners();

    _espera = Timer(const Duration(seconds: 5), () {
      if (!cargando) return;
      cargando = false;
      error = AppStrings.errorConexion;
      notifyListeners();
    });

    try {
      _sub = _origen().listen(_recibir, onError: (_) => _recibir(const []));
    } catch (_) {
      _recibir(const []);
    }
  }

  void _recibir(List<Map<String, dynamic>> lista) {
    _espera?.cancel();
    if (lista.isEmpty) {
      // Igual que el Home: si la colección está vacía se muestran ejemplos.
      deportes = DatosEjemplo.deportes;
      usandoEjemplo = true;
    } else {
      deportes = lista.map(Deporte.fromMap).toList();
      usandoEjemplo = false;
    }
    cargando = false;
    error = null;
    notifyListeners();
  }

  /// Deportes que cumplen la búsqueda y los filtros activos.
  List<Deporte> get deportesFiltrados {
    final texto = _normalizar(busqueda.trim());
    final diaElegido = dia == null ? null : _normalizar(dia!);
    return deportes.where((d) {
      final coincideTexto =
          texto.isEmpty ||
          _normalizar('${d.nombre} ${d.entrenadorNombre} ${d.descripcion}')
              .contains(texto);
      final hayCupo = !soloConCupos || d.estadoCupos != EstadoCupos.completo;
      final coincideDia =
          diaElegido == null || _normalizar(d.horario).contains(diaElegido);
      return coincideTexto && hayCupo && coincideDia;
    }).toList();
  }

  bool get hayFiltros =>
      busqueda.trim().isNotEmpty || soloConCupos || dia != null;

  void buscar(String texto) {
    busqueda = texto;
    notifyListeners();
  }

  void cambiarSoloConCupos(bool valor) {
    soloConCupos = valor;
    notifyListeners();
  }

  /// Elige un día; si se toca el mismo día otra vez, se quita el filtro.
  void elegirDia(String? nuevo) {
    dia = nuevo == dia ? null : nuevo;
    notifyListeners();
  }

  void limpiarFiltros() {
    busqueda = '';
    soloConCupos = false;
    dia = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  /// Minúsculas y sin tildes, para que "futbol" encuentre "Fútbol".
  static String _normalizar(String texto) {
    const conTilde = 'áéíóúü';
    const sinTilde = 'aeiouu';
    var resultado = texto.toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }
}
