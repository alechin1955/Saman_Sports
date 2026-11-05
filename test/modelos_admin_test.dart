import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/models/transaccion.dart';

void main() {
  final creado = DateTime(2026, 3, 2, 8);

  test('FranjaHorario y ReservaHorario conservan sus campos', () {
    const franja = FranjaHorario(dia: 1, horaInicio: 960, horaFin: 1080);
    expect(FranjaHorario.fromMap(franja.toMap()), franja);
    expect(franja.copyWith(dia: 3).dia, 3);

    final reserva = ReservaHorario(
      id: 'r1',
      canchaId: 'c1',
      canchaNombre: 'Cancha 1',
      dia: 1,
      horaInicio: 960,
      horaFin: 1080,
      fecha: null,
      tipo: TipoReserva.deporte,
      refId: 'dep-1',
      refNombre: 'Fútbol',
      activa: true,
    );
    final leida = ReservaHorario.fromMap(reserva.id, reserva.toMap());
    expect(leida.franja, franja);
    expect(leida.tipo, TipoReserva.deporte);
    expect(leida.refNombre, 'Fútbol');
    expect(leida.toMap().containsKey('id'), isFalse);
  });

  test('Cancha no guarda id ni version', () {
    const cancha = Cancha(
      id: 'c1',
      nombre: 'Cancha 1',
      ubicacion: 'Campus',
      descripcion: 'Fútbol',
      activa: true,
      version: 4,
    );
    final mapa = cancha.toMap();
    expect(mapa.containsKey('id'), isFalse);
    expect(mapa.containsKey('version'), isFalse);
    final leida = Cancha.fromMap(cancha.id, {...mapa, 'version': 4});
    expect(leida.nombre, cancha.nombre);
    expect(leida.version, 4);
  });

  test('Evento, ticket, transacción, notificación y pagos conservan datos', () {
    final evento = Evento(
      id: 'e1',
      titulo: 'Clásico',
      tipo: TipoEvento.partido,
      deporteId: 'dep-1',
      deporteNombre: 'Fútbol',
      canchaId: 'c1',
      canchaNombre: 'Cancha 1',
      fecha: '2026-03-02',
      horaInicio: 960,
      horaFin: 1080,
      descripcion: 'Partido interno',
      estado: EstadoEvento.pendiente,
      creadoPorUid: 'admin',
      creadoEn: creado,
    );
    final eventoLeido = Evento.fromMap(evento.id, evento.toMap());
    expect(eventoLeido.titulo, evento.titulo);
    expect(eventoLeido.franja.dia, DateTime.parse(evento.fecha).weekday);
    expect(eventoLeido.creadoEn, creado);

    final ticket = TicketSoporte(
      id: 't1',
      asunto: 'Cupo',
      categoria: 'inscripcion',
      descripcion: 'No aparece',
      autorUid: 'est-1',
      autorNombre: 'Ana',
      autorRol: 'estudiante',
      estado: EstadoTicket.abierto,
      fecha: creado,
    );
    expect(TicketSoporte.fromMap(ticket.id, ticket.toMap()).respuesta, '');

    final transaccion = Transaccion(
      id: 'tx1',
      fecha: creado,
      usuarioUid: 'admin',
      usuarioNombre: 'Admin',
      rol: 'administrador',
      accion: 'crear',
      modulo: 'canchas',
      descripcion: 'Creó una cancha',
    );
    expect(
      Transaccion.fromMap(transaccion.id, transaccion.toMap()).modulo,
      'canchas',
    );

    final aviso = Notificacion(
      id: 'n1',
      destinatarioUid: 'est-1',
      tipo: 'pago_pendiente',
      titulo: 'Pago',
      mensaje: 'Tienes un pago pendiente',
      periodo: '2026-II',
      leida: false,
      fecha: creado,
    );
    expect(
      Notificacion.fromMap(aviso.id, aviso.toMap()).tipo,
      'pago_pendiente',
    );

    final config = ConfiguracionPagos(
      periodo: '2026-II',
      fechaInicio: creado,
      fechaCorte: creado.add(const Duration(days: 30)),
      monto: 25,
    );
    final configLeida = ConfiguracionPagos.fromMap(config.toMap());
    expect(configLeida.periodo, '2026-II');
    expect(configLeida.monto, 25);
    expect(configLeida.fechaCorte, config.fechaCorte);
  });

  test('un deporte viejo sigue leyéndose y el mapa público no filtra datos privados', () {
    final viejo = Deporte.fromMap({
      'id': 'dep-1',
      'nombre': 'Fútbol',
      'horario': 'Lun y Mié, 4:00 p. m.',
      'cupos': 20,
      'inscritos': 10,
    });
    expect(viejo.entrenadorUid, '');
    expect(viejo.activo, isTrue);
    expect(viejo.canchaId, '');
    expect(viejo.horarios, isEmpty);
    expect(viejo.disponibles, 10);
    expect(viejo.toMap().containsKey('inscritos'), isFalse);

    final entrenador = EntrenadorAdmin.desdeMapas(
      'uid-1',
      {
        'nombre': 'Carlos',
        'apellido': 'Méndez',
        'disciplina': 'Fútbol',
        'descripcion': 'Campus',
        'activo': true,
        'especialidad': 'Juvenil',
        'anosExperiencia': 8,
      },
      {'cedula': 'V-1', 'correo': 'carlos@unimet.edu.ve', 'telefono': '0414'},
    );
    final publico = entrenador.toMapPublico();
    expect(publico.containsKey('cedula'), isFalse);
    expect(publico.containsKey('correo'), isFalse);
    expect(publico.containsKey('telefono'), isFalse);
    expect(entrenador.nombreCompleto, 'Carlos Méndez');
    expect(entrenador.toMapPrivado()['rol'], 'entrenador');
  });

  test('un pago sin PayPal guarda verificado y omite fechaPago', () {
    final pago = Pago(
      id: 'p1',
      inscripcionId: 'i1',
      estudianteUid: 'est-1',
      monto: 25,
      idTransaccion: 'PayPal simulado',
      estado: EstadoPago.pendiente,
      fecha: creado,
    );
    final mapa = pago.toMap();
    expect(mapa['verificado'], isFalse);
    expect(mapa.containsKey('fechaPago'), isFalse);
    expect(mapa.containsKey('paypalOrderId'), isFalse);
  });
}
