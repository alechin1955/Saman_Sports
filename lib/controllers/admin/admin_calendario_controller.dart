import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/bloque_ocupado.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_calendario_repository.dart';

class AdminCalendarioController extends ChangeNotifier {
  AdminCalendarioController({
    AdminCalendarioRepository? repositorio,
    DateTime Function()? ahora,
  }) : _repositorio = repositorio ?? FirebaseAdminCalendarioAdapter(),
       _ahora = ahora ?? DateTime.now;

  static const int jornadaInicio = 6 * 60;
  static const int jornadaFin = 22 * 60;
  static const int huecoMinimo = 30;

  final AdminCalendarioRepository _repositorio;
  final DateTime Function() _ahora;
  final List<StreamSubscription<Object>> _suscripciones = [];
  List<Cancha> canchas = [];
  List<ReservaHorario> reservas = [];
  String? canchaId;
  late DateTime lunes = _lunesDe(_ahora());
  bool cargando = false;
  String? error;
  bool _cerrado = false;
  bool _iniciado = false;
  bool _eligio = false;
  var _recibioCanchas = false;
  var _recibioReservas = false;

  List<Cancha> get canchasActivas {
    final activas = canchas.where((cancha) => cancha.activa).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return activas;
  }

  List<DateTime> get diasSemana {
    return [for (var i = 0; i < 7; i++) lunes.add(Duration(days: i))];
  }

  String get rangoSemana {
    final domingo = diasSemana.last;
    final inicio = _diaMes(lunes);
    final fin = lunes.month == domingo.month
        ? '${domingo.day} ${_mes(domingo)} ${domingo.year}'
        : _diaMes(domingo);
    return '$inicio – $fin';
  }

  void reintentar() {
    for (final sub in _suscripciones) {
      sub.cancel();
    }
    _suscripciones.clear();
    _iniciado = false;
    _recibioCanchas = false;
    _recibioReservas = false;
    iniciar();
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    lunes = _lunesDe(_ahora());
    cargando = true;
    error = null;
    _avisar();
    try {
      _suscripciones.add(
        _repositorio.canchas().listen(_recibirCanchas, onError: _fallo),
      );
      _suscripciones.add(
        _repositorio.reservasActivas().listen(_recibirReservas, onError: _fallo),
      );
    } catch (_) {
      _fallo(StateError(AppStrings.adminCalendarioError));
    }
  }

  void seleccionarCancha(String? id) {
    canchaId = id;
    _eligio = true;
    _avisar();
  }

  void semanaAnterior() => _mover(-7);

  void semanaSiguiente() => _mover(7);

  void irAHoy() {
    lunes = _lunesDe(_ahora());
    _avisar();
  }

  bool esHoy(DateTime dia) {
    final hoy = _ahora();
    return dia.year == hoy.year && dia.month == hoy.month && dia.day == hoy.day;
  }

  List<BloqueOcupado> bloquesDe(int dia) {
    final fecha = _iso(diasSemana[dia - 1]);
    final activas = {for (final cancha in canchasActivas) cancha.id};
    final bloques = <BloqueOcupado>[];
    for (final reserva in reservas) {
      if (!reserva.activa || !activas.contains(reserva.canchaId)) continue;
      if (canchaId != null && reserva.canchaId != canchaId) continue;
      final esEvento = reserva.tipo == TipoReserva.evento;
      if (esEvento) {
        if (reserva.fecha != fecha) continue;
      } else if (reserva.dia != dia) {
        continue;
      }
      final inicio = reserva.horaInicio < jornadaInicio
          ? jornadaInicio
          : reserva.horaInicio;
      final fin = reserva.horaFin > jornadaFin ? jornadaFin : reserva.horaFin;
      if (fin <= inicio) continue;
      bloques.add(
        BloqueOcupado(
          canchaId: reserva.canchaId,
          canchaNombre: reserva.canchaNombre,
          dia: dia,
          fecha: fecha,
          inicio: inicio,
          fin: fin,
          tipo: reserva.tipo,
          titulo: reserva.refNombre,
        ),
      );
    }
    bloques.sort((a, b) {
      final hora = a.inicio.compareTo(b.inicio);
      if (hora != 0) return hora;
      return a.canchaNombre.compareTo(b.canchaNombre);
    });
    return bloques;
  }

  List<FranjaLibre> huecosLibres(int dia) {
    if (canchaId == null) return const [];
    final ocupados = bloquesDe(dia);
    final huecos = <FranjaLibre>[];
    var cursor = jornadaInicio;
    for (final bloque in ocupados) {
      if (bloque.inicio - cursor >= huecoMinimo) {
        huecos.add(FranjaLibre(inicio: cursor, fin: bloque.inicio));
      }
      if (bloque.fin > cursor) cursor = bloque.fin;
    }
    if (jornadaFin - cursor >= huecoMinimo) {
      huecos.add(FranjaLibre(inicio: cursor, fin: jornadaFin));
    }
    return huecos;
  }

  void _recibirCanchas(List<Cancha> lista) {
    canchas = lista;
    _recibioCanchas = true;
    if (!_eligio) {
      final activas = canchasActivas;
      canchaId = activas.isEmpty ? null : activas.first.id;
    }
    _cerrarCarga();
  }

  void _recibirReservas(List<ReservaHorario> lista) {
    reservas = lista;
    _recibioReservas = true;
    _cerrarCarga();
  }

  void _cerrarCarga() {
    cargando = !(_recibioCanchas && _recibioReservas);
    if (_recibioCanchas && _recibioReservas) error = null;
    _avisar();
  }

  void _fallo(Object _) {
    cargando = false;
    error = AppStrings.adminCalendarioError;
    _avisar();
  }

  void _mover(int dias) {
    lunes = lunes.add(Duration(days: dias));
    _avisar();
  }

  DateTime _lunesDe(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return dia.subtract(Duration(days: dia.weekday - 1));
  }

  String _iso(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  String _mes(DateTime fecha) => AppStrings.adminMesesCortos[fecha.month - 1];

  String _diaMes(DateTime fecha) => '${fecha.day} ${_mes(fecha)} ${fecha.year}';

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    for (final sub in _suscripciones) {
      sub.cancel();
    }
    super.dispose();
  }
}
