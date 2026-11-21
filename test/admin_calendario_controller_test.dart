import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_calendario_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_calendario_repository.dart';

void main() {
  const reloj = _reloj;

  test('la semana parte el lunes y vuelve a hoy', () async {
    final controller = _controller(_Repo(listaCanchas: [_cancha('a', 'A')]));
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(controller.lunes, DateTime(2026, 11, 16));
    controller.semanaSiguiente();
    expect(controller.lunes, DateTime(2026, 11, 23));
    controller.irAHoy();
    expect(controller.lunes, DateTime(2026, 11, 16));
    controller.dispose();
  });

  test('el deporte se repite y el evento solo ocupa su fecha', () async {
    final controller = _controller(
      _Repo(
        listaCanchas: [_cancha('c1', 'Central')],
        listaReservas: [
          _reserva('futbol', canchaId: 'c1', dia: 1, inicio: 480, fin: 570),
          _reserva(
            'torneo',
            canchaId: 'c1',
            dia: 4,
            inicio: 600,
            fin: 660,
            tipo: TipoReserva.evento,
            fecha: '2026-11-19',
          ),
        ],
      ),
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(controller.bloquesDe(1).single.titulo, 'futbol');
    expect(controller.bloquesDe(4).single.titulo, 'torneo');
    controller.semanaSiguiente();
    expect(controller.bloquesDe(1).single.titulo, 'futbol');
    expect(controller.bloquesDe(4), isEmpty);
    controller.dispose();
  });

  test('filtra por cancha y por todas', () async {
    final controller = _controller(
      _Repo(
        listaCanchas: [_cancha('a', 'A'), _cancha('b', 'B')],
        listaReservas: [
          _reserva('uno', canchaId: 'a'),
          _reserva('dos', canchaId: 'b'),
        ],
      ),
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(controller.canchaId, 'a');
    expect(controller.bloquesDe(1).map((b) => b.titulo), ['uno']);
    controller.seleccionarCancha(null);
    expect(controller.bloquesDe(1).map((b) => b.titulo), ['uno', 'dos']);
    controller.dispose();
  });

  test('calcula huecos y omite los de menos de 30 minutos', () async {
    final controller = _controller(
      _Repo(
        listaCanchas: [_cancha('a', 'A')],
        listaReservas: [
          _reserva('manana', inicio: 480, fin: 570),
          _reserva('mediodia', inicio: 720, fin: 780),
        ],
      ),
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.huecosLibres(1).map((h) => (h.inicio, h.fin)),
      [(360, 480), (570, 720), (780, 1320)],
    );
    controller.dispose();

    final corto = _controller(
      _Repo(
        listaCanchas: [_cancha('a', 'A')],
        listaReservas: [
          _reserva('antes', inicio: 480, fin: 540),
          _reserva('despues', inicio: 560, fin: 620),
        ],
      ),
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(
      corto.huecosLibres(1).any((h) => h.fin - h.inicio == 20),
      isFalse,
    );
    corto.seleccionarCancha(null);
    expect(corto.huecosLibres(1), isEmpty);
    corto.dispose();
  });

  test('recorta a la jornada, ignora inactivas y elige la primera activa', () async {
    final controller = _controller(
      _Repo(
        listaCanchas: [_cancha('z', 'Zeta', activa: false), _cancha('b', 'Beta')],
        listaReservas: [
          _reserva('temprano', canchaId: 'b', inicio: 300, fin: 420),
          _reserva('noche', canchaId: 'b', inicio: 1290, fin: 1380),
          _reserva('fuera', canchaId: 'b', inicio: 240, fin: 330),
          _reserva('inactiva', canchaId: 'z'),
        ],
      ),
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(controller.canchaId, 'b');
    expect(controller.canchasActivas.map((c) => c.id), ['b']);
    final titulos = controller.bloquesDe(1);
    expect(titulos.map((b) => b.titulo), ['temprano', 'noche']);
    expect(titulos.first.inicio, 360);
    expect(titulos.last.fin, 1320);
    controller.dispose();
  });

  test('el error del stream queda visible y dispose no notifica', () async {
    final fuente = StreamController<List<Cancha>>.broadcast();
    final controller = AdminCalendarioController(
      ahora: reloj,
      repositorio: _Repo(canchasFuente: fuente),
    )..iniciar();
    fuente.addError(StateError('permiso'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.error, AppStrings.adminCalendarioError);
    var avisos = 0;
    controller.addListener(() => avisos++);
    controller.dispose();
    fuente.add([_cancha('a', 'A')]);
    await Future<void>.delayed(Duration.zero);
    expect(avisos, 0);
    await fuente.close();
  });
}

DateTime _reloj() => DateTime(2026, 11, 18, 10);

AdminCalendarioController _controller(AdminCalendarioRepository repo) {
  return AdminCalendarioController(repositorio: repo, ahora: _reloj);
}

Cancha _cancha(String id, String nombre, {bool activa = true}) {
  return Cancha(
    id: id,
    nombre: nombre,
    ubicacion: '',
    descripcion: '',
    activa: activa,
    version: 1,
  );
}

ReservaHorario _reserva(
  String titulo, {
  String canchaId = 'a',
  int dia = 1,
  int inicio = 480,
  int fin = 570,
  TipoReserva tipo = TipoReserva.deporte,
  String? fecha,
}) {
  return ReservaHorario(
    id: titulo,
    canchaId: canchaId,
    canchaNombre: canchaId,
    dia: dia,
    horaInicio: inicio,
    horaFin: fin,
    tipo: tipo,
    refId: titulo,
    refNombre: titulo,
    activa: true,
    fecha: fecha,
  );
}

class _Repo implements AdminCalendarioRepository {
  _Repo({
    this.listaCanchas = const [],
    this.listaReservas = const [],
    this.canchasFuente,
  });

  final List<Cancha> listaCanchas;
  final List<ReservaHorario> listaReservas;
  final StreamController<List<Cancha>>? canchasFuente;

  @override
  Stream<List<Cancha>> canchas() =>
      canchasFuente?.stream ?? Stream.value(listaCanchas);

  @override
  Stream<List<ReservaHorario>> reservasActivas() => Stream.value(listaReservas);
}
