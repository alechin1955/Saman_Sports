import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/utils/ticket_soporte_entrenador.dart';

void main() {
  test('construye el ticket con identidad y estado autoritativos', () {
    final fecha = DateTime(2026, 11, 8, 14);

    final ticket = construirTicketSoporteEntrenador(
      entrenadorUid: 'entrenador-1',
      perfil: const {
        'nombre': 'Juan',
        'apellido': 'Pérez',
        'correo': 'juan@unimet.edu.ve',
        'rol': 'entrenador',
      },
      categoria: ' asistencia ',
      asunto: ' Problema con asistencia ',
      descripcion: ' No aparece un alumno confirmado en la lista. ',
      fechaServidor: fecha,
    );

    expect(ticket, {
      'asunto': 'Problema con asistencia',
      'categoria': 'asistencia',
      'descripcion': 'No aparece un alumno confirmado en la lista.',
      'autorUid': 'entrenador-1',
      'autorNombre': 'Juan Pérez',
      'autorRol': 'entrenador',
      'estado': 'abierto',
      'respuesta': '',
      'fecha': fecha,
      'resueltoEn': null,
    });
  });

  test('rechaza una identidad que no pertenece a un entrenador', () {
    expect(
      () => construirTicketSoporteEntrenador(
        entrenadorUid: 'estudiante-1',
        perfil: const {'rol': 'estudiante'},
        categoria: 'otro',
        asunto: 'Necesito ayuda',
        descripcion: 'No puedo acceder a esta sección.',
        fechaServidor: DateTime(2026, 11, 8),
      ),
      throwsStateError,
    );
  });

  test('Firebase conserva el filtro y el constructor de seguridad', () async {
    final fuente = await File('lib/FirebaseServices.dart').readAsString();
    final inicioStream = fuente.indexOf('streamTicketsEntrenador({');
    final inicioCrear = fuente.indexOf('crearTicketEntrenador({', inicioStream);
    final finCrear = fuente.indexOf(
      'static DocumentReference<Map<String, dynamic>> _sesionAsistencia',
      inicioCrear,
    );
    expect(inicioStream, greaterThanOrEqualTo(0));
    expect(inicioCrear, greaterThan(inicioStream));
    expect(finCrear, greaterThan(inicioCrear));

    final stream = fuente.substring(inicioStream, inicioCrear);
    final crear = fuente.substring(inicioCrear, finCrear);
    expect(
      stream,
      contains(".where('autorUid', isEqualTo: entrenadorUid)"),
      reason: 'La consulta debe estar limitada al UID autenticado.',
    );
    expect(
      crear,
      contains('construirTicketSoporteEntrenador('),
      reason: 'La escritura debe usar el constructor autoritativo probado.',
    );
    expect(
      crear,
      contains('fechaServidor: FieldValue.serverTimestamp()'),
      reason: 'La fecha debe proceder del servidor.',
    );
  });
}
