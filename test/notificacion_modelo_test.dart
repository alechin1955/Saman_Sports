import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/models/notificacion.dart';

void main() {
  test('fromMap y toMap conservan los campos nuevos', () {
    final fecha = DateTime(2026, 11, 21);
    final aviso = Notificacion.fromMap('n1', {
      'destinatarioUid': 'u1',
      'destinatarioRol': 'estudiante',
      'origenUid': 'admin',
      'tipo': 'evento_confirmar',
      'titulo': 'Evento',
      'mensaje': 'Confirma',
      'periodo': '',
      'leida': false,
      'fecha': fecha,
      'eventoId': 'ev1',
      'inscripcionId': 'i1',
      'pagoId': 'p1',
      'ticketId': 't1',
      'deporteId': 'dep1',
    });

    expect(aviso.pideConfirmacion, isTrue);
    expect(aviso.toMap()['eventoId'], 'ev1');
    expect(aviso.toMap()['deporteId'], 'dep1');
    expect(
      Notificacion.fromMap('n2', {'tipo': 'evento_info'}).pideConfirmacion,
      isFalse,
    );
  });
}
