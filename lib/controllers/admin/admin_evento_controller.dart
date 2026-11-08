import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_evento_repository.dart';

class AdminEventoController extends ChangeNotifier {
  AdminEventoController({
    AdminEventoRepository? repository,
    DateTime Function()? reloj,
  }) : _repository = repository ?? FirebaseAdminEventoAdapter(),
       _reloj = reloj ?? DateTime.now;

  static const String tituloObligatorio = 'El título es obligatorio.';
  static const String canchaObligatoria = 'Elige una cancha.';
  static const String fechaPasada = 'La fecha no puede ser anterior a hoy.';
  static const String fechaInvalida = 'La fecha no es válida.';
  static const String eventoCreado = 'Evento guardado.';

  final AdminEventoRepository _repository;
  final DateTime Function() _reloj;
  List<Evento> eventos = [];
  List<Deporte> deportes = [];
  List<Cancha> canchas = [];
  List<ReservaHorario> reservasCancha = [];
  EstadoEvento? filtroEstado;
  TipoEvento? filtroTipo;
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  int _escuchas = 0;
  StreamSubscription<List<Evento>>? _eventosSub;
  StreamSubscription<List<Deporte>>? _deportesSub;
  StreamSubscription<List<Cancha>>? _canchasSub;
  StreamSubscription<List<ReservaHorario>>? _reservasSub;

  int get escuchas => _escuchas;

  List<Evento> get eventosFiltrados {
    return eventos.where((evento) {
      if (filtroEstado != null && evento.estado != filtroEstado) return false;
      if (filtroTipo != null && evento.tipo != filtroTipo) return false;
      return true;
    }).toList();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    _escuchas++;
    cargando = true;
    _avisar();
    _eventosSub = _repository.eventos().listen((lista) {
      eventos = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar los eventos.'));
    _canchasSub = _repository.canchas().listen((lista) {
      canchas = lista;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar las canchas.'));
    _deportesSub = _repository.deportes().listen((lista) {
      deportes = lista.where((deporte) => deporte.activo).toList();
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar las disciplinas.'));
  }

  List<Deporte> get deportesActivos => deportes;

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

  void filtrar({EstadoEvento? estado, TipoEvento? tipo, bool limpiar = false}) {
    if (limpiar) {
      filtroEstado = null;
      filtroTipo = null;
    } else {
      filtroEstado = estado;
      filtroTipo = tipo;
    }
    _avisar();
  }

  String? validarEvento({
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    String? ignorarEventoId,
    String? deporteId,
  }) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) return fechaInvalida;
    final parseada = DateTime.tryParse(fecha);
    if (parseada == null) return fechaInvalida;
    final dia = DateTime(parseada.year, parseada.month, parseada.day);
    final ahora = _reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    if (dia.isBefore(hoy)) return fechaPasada;
    final errorFranja = validarFranja(
      FranjaHorario(dia: dia.weekday, horaInicio: horaInicio, horaFin: horaFin),
    );
    if (errorFranja != null) return errorFranja;
    final cancha = canchas.cast<Cancha?>().firstWhere(
      (item) => item?.id == canchaId,
      orElse: () => null,
    );
    final nueva = ReservaHorario(
      id: '',
      canchaId: canchaId,
      canchaNombre: cancha?.nombre ?? '',
      dia: dia.weekday,
      horaInicio: horaInicio,
      horaFin: horaFin,
      fecha: fecha,
      tipo: TipoReserva.evento,
      refId: ignorarEventoId ?? '',
      refNombre: '',
      activa: true,
    );
    final resultado = evaluarChoqueEvento(
      nuevas: [nueva],
      existentes: reservasCancha.where((r) => r.canchaId == canchaId).toList(),
      ignorarRefId: ignorarEventoId,
      deporteId: deporteId,
    );
    return resultado.choque == null ? null : mensajeChoque(resultado.choque!);
  }

  bool reemplazaPractica({
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    String? deporteId,
    String? ignorarEventoId,
  }) {
    if (deporteId == null || deporteId.isEmpty) return false;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) return false;
    final parseada = DateTime.tryParse(fecha);
    if (parseada == null) return false;
    final nueva = ReservaHorario(
      id: '',
      canchaId: canchaId,
      canchaNombre: '',
      dia: parseada.weekday,
      horaInicio: horaInicio,
      horaFin: horaFin,
      fecha: fecha,
      tipo: TipoReserva.evento,
      refId: ignorarEventoId ?? '',
      refNombre: '',
      activa: true,
    );
    return evaluarChoqueEvento(
      nuevas: [nueva],
      existentes: reservasCancha.where((r) => r.canchaId == canchaId).toList(),
      ignorarRefId: ignorarEventoId,
      deporteId: deporteId,
    ).ignoroPractica;
  }

  Future<String?> crearEvento({
    required String titulo,
    required TipoEvento tipo,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    required String descripcion,
    String? deporteId,
    String? deporteNombre,
  }) {
    return _guardar(() async {
      if (titulo.trim().isEmpty) return tituloObligatorio;
      if (canchaId.trim().isEmpty) return canchaObligatoria;
      final choque = validarEvento(
        canchaId: canchaId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        deporteId: deporteId,
      );
      if (choque != null) return choque;
      final reemplaza = reemplazaPractica(
        canchaId: canchaId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        deporteId: deporteId,
      );
      final error = await _repository.crearEvento(
        canchaId: canchaId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        datos: {
          'titulo': titulo.trim(),
          'tipo': tipo.valor,
          'descripcion': descripcion.trim(),
          'deporteId': deporteId,
          'deporteNombre': deporteNombre,
          'reemplazaPractica': reemplaza,
        },
      );
      return error;
    }, eventoCreado);
  }

  Future<String?> actualizarEvento({
    required Evento evento,
    required String titulo,
    required String descripcion,
    String? canchaId,
    String? fecha,
    int? horaInicio,
    int? horaFin,
  }) {
    return _guardar(() async {
      if (titulo.trim().isEmpty) return tituloObligatorio;
      final cambiaHorario =
          canchaId != null ||
          fecha != null ||
          horaInicio != null ||
          horaFin != null;
      if (cambiaHorario) {
        final choque = validarEvento(
          canchaId: canchaId ?? evento.canchaId,
          fecha: fecha ?? evento.fecha,
          horaInicio: horaInicio ?? evento.horaInicio,
          horaFin: horaFin ?? evento.horaFin,
          ignorarEventoId: evento.id,
          deporteId: evento.deporteId,
        );
        if (choque != null) return choque;
      }
      return _repository.actualizarEvento(
        id: evento.id,
        canchaId: canchaId,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        datos: {'titulo': titulo.trim(), 'descripcion': descripcion.trim()},
      );
    }, 'Evento actualizado.');
  }

  Future<String?> cambiarEstado(Evento evento, EstadoEvento estado) {
    return _guardar(() async {
      final error = await _repository.cambiarEstadoEvento(
        id: evento.id,
        estado: estado.valor,
      );
      if (error != null ||
          estado != EstadoEvento.aprobado ||
          evento.deporteId == null ||
          evento.deporteId!.isEmpty) {
        return error;
      }
      return _repository.notificarInscritos(
        deporteId: evento.deporteId!,
        titulo: evento.titulo,
        fecha: evento.fecha,
        horaInicio: evento.horaInicio,
        horaFin: evento.horaFin,
        canchaNombre: _nombreCancha(evento.canchaId),
        reemplazaPractica: evento.reemplazaPractica,
      );
    }, 'Estado del evento actualizado.');
  }

  String _nombreCancha(String canchaId) {
    final cancha = canchas.cast<Cancha?>().firstWhere(
      (item) => item?.id == canchaId,
      orElse: () => null,
    );
    return cancha?.nombre ?? '';
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
    _eventosSub?.cancel();
    _deportesSub?.cancel();
    _canchasSub?.cancel();
    _reservasSub?.cancel();
    super.dispose();
  }
}
