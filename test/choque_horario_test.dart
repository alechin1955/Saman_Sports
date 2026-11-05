import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/reserva_horario.dart';

void main() {
  ReservaHorario reserva({
    String id = 'r1',
    String canchaId = 'c1',
    int dia = 1,
    int horaInicio = 480,
    int horaFin = 600,
    String? fecha,
    String refId = 'dep-1',
    bool activa = true,
    TipoReserva tipo = TipoReserva.deporte,
  }) {
    return ReservaHorario(
      id: id,
      canchaId: canchaId,
      canchaNombre: 'Cancha 1',
      dia: dia,
      horaInicio: horaInicio,
      horaFin: horaFin,
      fecha: fecha,
      tipo: tipo,
      refId: refId,
      refNombre: 'Fútbol',
      activa: activa,
    );
  }

  String fechaDe(int weekday) {
    var dia = DateTime(2026, 3, 1);
    while (dia.weekday != weekday) {
      dia = dia.add(const Duration(days: 1));
    }
    final mes = dia.month.toString().padLeft(2, '0');
    final numero = dia.day.toString().padLeft(2, '0');
    return '${dia.year}-$mes-$numero';
  }

  test('los bordes que se tocan no chocan', () {
    expect(seSolapan(480, 600, 600, 720), isFalse);
    expect(
      reservasChocan(
        reserva(),
        reserva(id: 'r2', horaInicio: 600, horaFin: 720),
      ),
      isFalse,
    );
  });

  test('el solapamiento parcial y el total chocan', () {
    expect(seSolapan(480, 600, 540, 660), isTrue);
    expect(seSolapan(480, 720, 540, 600), isTrue);
    expect(
      reservasChocan(
        reserva(),
        reserva(id: 'r2', horaInicio: 540, horaFin: 660),
      ),
      isTrue,
    );
  });

  test('una franja contenida dentro de otra choca', () {
    expect(
      reservasChocan(
        reserva(horaFin: 720),
        reserva(id: 'r2', horaInicio: 540, horaFin: 600),
      ),
      isTrue,
    );
  });

  test('el mismo horario en otra cancha no choca', () {
    expect(
      reservasChocan(reserva(), reserva(id: 'r2', canchaId: 'c2')),
      isFalse,
    );
  });

  test('otro día no choca', () {
    expect(reservasChocan(reserva(), reserva(id: 'r2', dia: 2)), isFalse);
  });

  test('una reserva inactiva no choca', () {
    expect(
      reservasChocan(reserva(), reserva(id: 'r2', activa: false)),
      isFalse,
    );
  });

  test('ignorarRefId no choca con la propia reserva al editar', () {
    final propia = reserva(id: 'vieja', refId: 'dep-1');
    final ajena = reserva(
      id: 'ajena',
      refId: 'dep-2',
      horaInicio: 540,
      horaFin: 660,
    );
    expect(
      buscarChoque(
        nuevas: [reserva(id: 'nueva', horaInicio: 540, horaFin: 660)],
        existentes: [propia, ajena],
        ignorarRefId: 'dep-1',
      )?.id,
      'ajena',
    );
    expect(
      buscarChoque(
        nuevas: [reserva(id: 'nueva')],
        existentes: [propia],
        ignorarRefId: 'dep-1',
      ),
      isNull,
    );
  });

  test('un choque entre franjas nuevas devuelve la segunda', () {
    final segunda = reserva(id: 'b', horaInicio: 540, horaFin: 660);
    expect(
      buscarChoque(
        nuevas: [
          reserva(id: 'a'),
          segunda,
        ],
        existentes: const [],
      )?.id,
      'b',
    );
  });

  test('una reserva semanal choca con un evento de ese weekday', () {
    final lunes = fechaDe(DateTime.monday);
    expect(
      reservasChocan(
        reserva(),
        reserva(
          id: 'evento',
          fecha: lunes,
          tipo: TipoReserva.evento,
          refId: 'ev-1',
        ),
      ),
      isTrue,
    );
  });

  test('una reserva semanal no choca con un evento de otro weekday', () {
    final martes = fechaDe(DateTime.tuesday);
    expect(
      reservasChocan(
        reserva(),
        reserva(id: 'evento', fecha: martes, dia: 2, tipo: TipoReserva.evento),
      ),
      isFalse,
    );
  });

  test('dos eventos chocan solo si comparten fecha', () {
    final lunes = fechaDe(DateTime.monday);
    final otroLunes = fechaDe(DateTime.monday);
    expect(
      reservasChocan(
        reserva(fecha: lunes, tipo: TipoReserva.evento),
        reserva(id: 'e2', fecha: otroLunes, tipo: TipoReserva.evento),
      ),
      isTrue,
    );
    expect(
      reservasChocan(
        reserva(fecha: lunes, tipo: TipoReserva.evento),
        reserva(
          id: 'e3',
          fecha: fechaDe(DateTime.tuesday),
          dia: 2,
          tipo: TipoReserva.evento,
        ),
      ),
      isFalse,
    );
  });

  test('validarFranja rechaza inicio mayor o igual, menos de 30 min y día inválido', () {
    expect(
      validarFranja(const FranjaHorario(dia: 1, horaInicio: 600, horaFin: 600)),
      isNotNull,
    );
    expect(
      validarFranja(const FranjaHorario(dia: 1, horaInicio: 600, horaFin: 620)),
      isNotNull,
    );
    expect(
      validarFranja(const FranjaHorario(dia: 0, horaInicio: 480, horaFin: 600)),
      isNotNull,
    );
    expect(
      validarFranja(const FranjaHorario(dia: 8, horaInicio: 480, horaFin: 600)),
      isNotNull,
    );
    expect(
      validarFranja(const FranjaHorario(dia: 1, horaInicio: 480, horaFin: 510)),
      isNull,
    );
  });

  test('textoHorario agrupa 1, 2 y 3 días y separa horarios distintos', () {
    expect(abreviaturasDias, ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']);
    expect(
      textoHorario([
        const FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080),
      ]),
      'Lun 16:00–18:00',
    );
    expect(
      textoHorario([
        const FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080),
        const FranjaHorario(dia: 3, horaInicio: 960, horaFin: 1080),
      ]),
      'Lun y Mié 16:00–18:00',
    );
    expect(
      textoHorario([
        const FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080),
        const FranjaHorario(dia: 3, horaInicio: 960, horaFin: 1080),
        const FranjaHorario(dia: 5, horaInicio: 960, horaFin: 1080),
      ]),
      'Lun, Mié y Vie 16:00–18:00',
    );
    expect(
      textoHorario([
        const FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080),
        const FranjaHorario(dia: 3, horaInicio: 960, horaFin: 1080),
        const FranjaHorario(dia: 5, horaInicio: 480, horaFin: 600),
      ], cancha: 'Cancha 1'),
      'Lun y Mié 16:00–18:00 · Vie 08:00–10:00 · Cancha 1',
    );
    expect(textoHorario(const []), '');
    expect(minutosATexto(425), '07:05');
    expect(textoAMinutos('07:05'), 425);
  });

  test('mensajeChoque distingue reserva semanal y evento con fecha', () {
    expect(
      mensajeChoque(reserva(horaInicio: 960, horaFin: 1080)),
      'La cancha Cancha 1 ya está ocupada el Lun de 16:00 a 18:00 por Fútbol (deporte).',
    );
    expect(
      mensajeChoque(
        reserva(
          fecha: '2026-03-15',
          dia: 7,
          horaInicio: 960,
          horaFin: 1080,
          tipo: TipoReserva.evento,
        ),
      ),
      'La cancha Cancha 1 ya está ocupada el 15/03/2026 de 16:00 a 18:00 por Fútbol (evento).',
    );
  });
}
