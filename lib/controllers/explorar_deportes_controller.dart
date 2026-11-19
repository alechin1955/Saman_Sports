import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
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

  /// Días que se pueden filtrar. La posición + 1 es el número de día que
  /// guarda el administrador en `horarios` (1 = lunes … 7 = domingo).
  static const List<String> dias = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  final OrigenDeportes _origen;

  List<Deporte> deportes = [];
  bool cargando = true;
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
      _sub = _origen().listen(_recibir, onError: (_) => _fallar());
    } catch (_) {
      _fallar();
    }
  }

  /// Solo se muestran los deportes que publicó el administrador.
  /// Si todavía no hay ninguno, la lista queda vacía (sin datos inventados).
  void _recibir(List<Map<String, dynamic>> lista) {
    _espera?.cancel();
    deportes = lista.map(Deporte.fromMap).toList();
    cargando = false;
    error = null;
    notifyListeners();
  }

  void _fallar() {
    _espera?.cancel();
    cargando = false;
    error = AppStrings.errorConexion;
    notifyListeners();
  }

  /// true cuando el administrador todavía no ha publicado disciplinas.
  bool get sinPublicar => !cargando && error == null && deportes.isEmpty;

  /// Deportes que cumplen la búsqueda y los filtros activos.
  List<Deporte> get deportesFiltrados {
    final texto = _normalizar(busqueda.trim());
    return deportes.where((d) {
      final coincideTexto =
          texto.isEmpty ||
          _normalizar('${d.nombre} ${d.entrenadorNombre} ${d.descripcion}')
              .contains(texto);
      final hayCupo = !soloConCupos || d.estadoCupos != EstadoCupos.completo;
      final coincideDia = dia == null || tieneClaseEl(d, dia!);
      return coincideTexto && hayCupo && coincideDia;
    }).toList();
  }

  /// El deporte tiene clase ese día. Usa las franjas del administrador
  /// (`horarios`); si un deporte viejo no las tiene, revisa el texto.
  static bool tieneClaseEl(Deporte deporte, String dia) {
    final numero = dias.indexOf(dia) + 1;
    if (deporte.horarios.isNotEmpty) {
      return deporte.horarios.any((franja) => franja.dia == numero);
    }
    return _normalizar(deporte.horario).contains(_normalizar(dia));
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