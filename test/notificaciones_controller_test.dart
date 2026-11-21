import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/notificaciones_controller.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/repositories/notificaciones_repository.dart';

void main() {
  test('sin sesión no escucha avisos', () async {
    final repo = _Repo();
    final controller = NotificacionesController(repositorio: repo)..iniciar();
    repo.sesion.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(repo.propiasEscuchadas, 0);
    expect(controller.notificaciones, isEmpty);
    controller.dispose();
  });

  test('estudiante solo escucha las propias y cuenta no leídas', () async {
    final repo = _Repo(rol: 'estudiante');
    final controller = NotificacionesController(repositorio: repo)..iniciar();
    repo.sesion.add('est1');
    await Future<void>.delayed(Duration.zero);
    repo.fuente.add([
      _aviso('a', leida: false, dia: 1),
      _aviso('b', leida: true, dia: 3),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(repo.bandejaEscuchadas, 0);
    expect(controller.notificaciones.map((a) => a.id), ['b', 'a']);
    expect(controller.noLeidas, 1);
    controller.dispose();
  });

  test('admin junta propias y bandeja', () async {
    final repo = _Repo(rol: 'administrador');
    final controller = NotificacionesController(repositorio: repo)..iniciar();
    repo.sesion.add('admin1');
    await Future<void>.delayed(Duration.zero);
    repo.fuente.add([_aviso('propia')]);
    repo.bandeja.add([_aviso('bandeja', rol: 'administrador')]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.notificaciones.map((a) => a.id), containsAll(['propia', 'bandeja']));
    controller.dispose();
  });

  test('marcarLeida y responder usan el aviso recibido', () async {
    final repo = _Repo(rol: 'estudiante');
    final controller = NotificacionesController(repositorio: repo)..iniciar();
    final propia = _aviso('p');
    final admin = _aviso('ad', rol: 'administrador');
    expect(await controller.marcarLeida(propia), isNull);
    expect(await controller.marcarLeida(admin), isNull);
    expect(repo.marcadas.map((a) => a.destinatarioRol), ['estudiante', 'administrador']);
    expect(await controller.responder(propia, true), isNull);
    expect(repo.respuestas, [(propia.id, true)]);
    controller.dispose();
  });

  test('un error del stream queda en error', () async {
    final repo = _Repo(rol: 'estudiante');
    final controller = NotificacionesController(repositorio: repo)..iniciar();
    repo.sesion.add('est1');
    await Future<void>.delayed(Duration.zero);
    repo.fuente.addError(StateError('permiso'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.error, contains('permiso'));
    controller.dispose();
  });

  test('después de dispose no notifica', () async {
    final repo = _Repo();
    final controller = NotificacionesController(repositorio: repo)..iniciar();
    var avisos = 0;
    controller.addListener(() => avisos++);
    controller.dispose();
    final antes = avisos;
    repo.sesion.add('est1');
    await Future<void>.delayed(Duration.zero);
    expect(avisos, antes);
  });
}

Notificacion _aviso(String id, {bool leida = false, int dia = 1, String rol = 'estudiante'}) {
  return Notificacion(
    id: id,
    destinatarioUid: rol == 'administrador' ? '' : 'est1',
    destinatarioRol: rol,
    tipo: 'evento_info',
    titulo: id,
    mensaje: id,
    periodo: '',
    leida: leida,
    fecha: DateTime(2026, 11, dia),
    eventoId: 'ev',
  );
}

class _Repo implements NotificacionesRepository {
  _Repo({this.rol = 'estudiante'});

  final String rol;
  final sesion = StreamController<String?>.broadcast();
  final fuente = StreamController<List<Notificacion>>.broadcast();
  final bandeja = StreamController<List<Notificacion>>.broadcast();
  var propiasEscuchadas = 0;
  var bandejaEscuchadas = 0;
  final marcadas = <Notificacion>[];
  final respuestas = <(String, bool)>[];

  @override
  Stream<String?> uidSesion() => sesion.stream;

  @override
  Future<String?> rolDe(String uid) async => rol;

  @override
  Stream<List<Notificacion>> propias(String uid) {
    propiasEscuchadas++;
    return fuente.stream;
  }

  @override
  Stream<List<Notificacion>> bandejaAdmin() {
    bandejaEscuchadas++;
    return bandeja.stream;
  }

  @override
  Future<String?> marcarLeida(Notificacion aviso) async {
    marcadas.add(aviso);
    return null;
  }

  @override
  Future<String?> responderParticipacion(Notificacion aviso, bool asistira) async {
    respuestas.add((aviso.id, asistira));
    return null;
  }
}
