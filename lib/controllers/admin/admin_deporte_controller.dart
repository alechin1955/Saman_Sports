import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_deporte_repository.dart';

enum FiltroDeporte { todos, activos, inactivos }

class AdminDeporteController extends ChangeNotifier {
  AdminDeporteController({AdminDeporteRepository? repository})
    : _repository = repository ?? FirebaseAdminDeporteAdapter();

  static const String nombreObligatorio = 'El nombre es obligatorio.';
  static const String cuposInvalidos = 'Los cupos deben ser mayores que cero.';
  static const String canchaObligatoria = 'Elige una cancha.';
  static const String horarioObligatorio = 'Agrega al menos un horario.';
  static const String deporteCreado = 'Deporte guardado.';
  static const String deporteActualizado = 'Deporte actualizado.';
  static const String canchaCreada = 'Cancha guardada.';
  static const String canchaActualizada = 'Cancha actualizada.';

  final AdminDeporteRepository _repository;
  List<Deporte> deportes = [];
  List<Cancha> canchas = [];
  List<ReservaHorario> reservasCancha = [];
  FiltroDeporte filtro = FiltroDeporte.todos;
  String busqueda = '';
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  int _escuchas = 0;
  StreamSubscription<List<Deporte>>? _deportesSub;
  StreamSubscription<List<Cancha>>? _canchasSub;
  StreamSubscription<List<ReservaHorario>>? _reservasSub;

  int get escuchas => _escuchas;

  List<Cancha> get canchasActivas =>
      canchas.where((cancha) => cancha.activa).toList();

  List<Deporte> get deportesFiltrados {
    final texto = busqueda.trim().toLowerCase();
    return deportes.where((deporte) {
      final visible = switch (filtro) {
        FiltroDeporte.activos => deporte.activo,
        FiltroDeporte.inactivos => !deporte.activo,
        FiltroDeporte.todos => true,
      };
      if (!visible) return false;
      if (texto.isEmpty) return true;
      return '${deporte.nombre} ${deporte.entrenadorNombre}'
          .toLowerCase()
          .contains(texto);
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    _escuchas++;
    cargando = true;
    _avisar();
    _deportesSub = _repository.deportes().listen((lista) {
      deportes = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar los deportes.'));
    _canchasSub = _repository.canchas().listen((lista) {
      canchas = lista;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar las canchas.'));
  }

  void observarCancha(String? canchaId) {
    _reservasSub?.cancel();
    reservasCancha = [];
    if (canchaId == null || canchaId.isEmpty || _cerrado) {
      _avisar();
      return;
    }
    _reservasSub = _repository.reservasCancha(canchaId).listen((lista) {
      reservasCancha = lista;
      _avisar();
    }, onError: (_) => _fallo('No se pudo cargar la ocupación de la cancha.'));
  }

  void cambiarFiltro(FiltroDeporte valor) {
    filtro = valor;
    _avisar();
  }

  void buscar(String texto) {
    busqueda = texto;
    _avisar();
  }

  String? validarHorario({
    required String canchaId,
    required List<FranjaHorario> franjas,
    String? ignorarDeporteId,
  }) {
    for (final franja in franjas) {
      final errorFranja = validarFranja(franja);
      if (errorFranja != null) return errorFranja;
    }
    final cancha = canchas.cast<Cancha?>().firstWhere(
      (item) => item?.id == canchaId,
      orElse: () => null,
    );
    final nuevas = franjas
        .map(
          (franja) => ReservaHorario(
            id: '',
            canchaId: canchaId,
            canchaNombre: cancha?.nombre ?? '',
            dia: franja.dia,
            horaInicio: franja.horaInicio,
            horaFin: franja.horaFin,
            tipo: TipoReserva.deporte,
            refId: ignorarDeporteId ?? '',
            refNombre: '',
            activa: true,
          ),
        )
        .toList();
    final choque = buscarChoque(
      nuevas: nuevas,
      existentes: reservasCancha.where((r) => r.canchaId == canchaId).toList(),
      ignorarRefId: ignorarDeporteId,
    );
    return choque == null ? null : mensajeChoque(choque);
  }

  Future<String?> crearDeporte({
    required String nombre,
    required String descripcion,
    required String icono,
    required int cupos,
    required String canchaId,
    required List<FranjaHorario> franjas,
    String entrenadorUid = '',
    String entrenadorNombre = '',
  }) {
    return _guardar(() async {
      if (nombre.trim().isEmpty) return nombreObligatorio;
      if (cupos <= 0) return cuposInvalidos;
      if (canchaId.trim().isEmpty) return canchaObligatoria;
      if (franjas.isEmpty) return horarioObligatorio;
      final choque = validarHorario(canchaId: canchaId, franjas: franjas);
      if (choque != null) return choque;
      final cancha = _cancha(canchaId);
      return _repository.crearDeporte(
        canchaId: canchaId,
        franjas: franjas.map((franja) => franja.toMap()).toList(),
        datos: {
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim(),
          'icono': icono,
          'cupos': cupos,
          'entrenadorUid': entrenadorUid,
          'entrenadorNombre': entrenadorNombre,
          'canchaNombre': cancha?.nombre ?? '',
        },
      );
    }, deporteCreado);
  }

  Future<String?> actualizarDeporte({
    required Deporte deporte,
    required String nombre,
    required String descripcion,
    required String icono,
    required int cupos,
    String? canchaId,
    List<FranjaHorario>? franjas,
  }) {
    return _guardar(() async {
      if (nombre.trim().isEmpty) return nombreObligatorio;
      if (cupos <= 0) return cuposInvalidos;
      final canchaDestino = canchaId ?? deporte.canchaId;
      if (franjas != null) {
        final choque = validarHorario(
          canchaId: canchaDestino,
          franjas: franjas,
          ignorarDeporteId: deporte.id,
        );
        if (choque != null) return choque;
      }
      return _repository.actualizarDeporte(
        id: deporte.id,
        canchaId: canchaId,
        franjas: franjas?.map((franja) => franja.toMap()).toList(),
        datos: {
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim(),
          'icono': icono,
          'cupos': cupos,
        },
      );
    }, deporteActualizado);
  }

  Future<String?> cambiarEstadoDeporte(Deporte deporte, bool activo) {
    return _guardar(
      () => _repository.cambiarEstadoDeporte(id: deporte.id, activo: activo),
      activo ? 'Deporte activado.' : 'Deporte desactivado.',
    );
  }

  Future<String?> asignarEntrenador(
    Deporte deporte,
    EntrenadorAdmin? entrenador,
  ) {
    return _guardar(
      () => _repository.asignarEntrenador(
        deporteId: deporte.id,
        entrenadorUid: entrenador?.uid ?? '',
        entrenadorNombre: entrenador?.nombreCompleto ?? '',
      ),
      entrenador == null ? 'Entrenador desasignado.' : 'Entrenador asignado.',
    );
  }

  Future<String?> crearCancha({
    required String nombre,
    required String ubicacion,
    required String descripcion,
  }) {
    return _guardar(() async {
      if (nombre.trim().isEmpty) return nombreObligatorio;
      return _repository.crearCancha(
        nombre: nombre.trim(),
        ubicacion: ubicacion.trim(),
        descripcion: descripcion.trim(),
      );
    }, canchaCreada);
  }

  Future<String?> actualizarCancha({
    required Cancha cancha,
    required String nombre,
    required String ubicacion,
    required String descripcion,
  }) {
    return _guardar(() async {
      if (nombre.trim().isEmpty) return nombreObligatorio;
      return _repository.actualizarCancha(
        id: cancha.id,
        nombre: nombre.trim(),
        ubicacion: ubicacion.trim(),
        descripcion: descripcion.trim(),
        activa: cancha.activa,
      );
    }, canchaActualizada);
  }

  Future<String?> cambiarEstadoCancha(Cancha cancha, bool activa) {
    return _guardar(
      () => _repository.actualizarCancha(
        id: cancha.id,
        nombre: cancha.nombre,
        ubicacion: cancha.ubicacion,
        descripcion: cancha.descripcion,
        activa: activa,
      ),
      activa ? 'Cancha activada.' : 'Cancha desactivada.',
    );
  }

  Cancha? _cancha(String id) {
    for (final cancha in canchas) {
      if (cancha.id == id) return cancha;
    }
    return null;
  }

  Future<String?> _guardar(
    Future<String?> Function() accion,
    String exito,
  ) async {
    if (_cerrado) return 'La operación ya no está disponible.';
    guardando = true;
    error = null;
    mensaje = null;
    _avisar();
    try {
      final resultado = await accion();
      if (_cerrado) return resultado;
      if (resultado == null) {
        mensaje = exito;
      } else {
        error = resultado;
      }
      return resultado;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
  }

  void _fallo(String texto) {
    if (_cerrado) return;
    cargando = false;
    error = texto;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _deportesSub?.cancel();
    _canchasSub?.cancel();
    _reservasSub?.cancel();
    super.dispose();
  }
}
