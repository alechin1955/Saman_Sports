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

  test('valida categoría y límites de texto en un único contrato', () {
    const asunto = 'Necesito ayuda';
    const descripcion = 'No puedo acceder a esta sección.';
    expect(
      validarTicketSoporteEntrenador(
        categoria: 'otro',
        asunto: asunto,
        descripcion: descripcion,
      ),
      isNull,
    );

    final invalidos = [
      (categoria: 'invalida', asunto: asunto, descripcion: descripcion),
      (categoria: 'otro', asunto: '1234', descripcion: descripcion),
      (
        categoria: 'otro',
        asunto: List.filled(81, 'a').join(),
        descripcion: descripcion,
      ),
      (categoria: 'otro', asunto: asunto, descripcion: '123456789'),
      (
        categoria: 'otro',
        asunto: asunto,
        descripcion: List.filled(501, 'a').join(),
      ),
    ];
    for (final caso in invalidos) {
      expect(
        validarTicketSoporteEntrenador(
          categoria: caso.categoria,
          asunto: caso.asunto,
          descripcion: caso.descripcion,
        ),
        isNotNull,
      );
    }
  });

  test('rechaza un UID vacío aunque el perfil diga entrenador', () {
    expect(
      () => construirTicketSoporteEntrenador(
        entrenadorUid: '',
        perfil: const {'rol': 'entrenador'},
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
      stream,
      contains('actual == null || actual != entrenadorUid'),
      reason: 'La consulta debe pertenecer a la sesión autenticada.',
    );
    expect(
      crear,
      contains('construirTicketSoporteEntrenador('),
      reason: 'La escritura debe usar el constructor autoritativo probado.',
    );
    expect(
      crear,
      contains('actual == null || actual != entrenadorUid'),
      reason: 'La escritura debe pertenecer a la sesión autenticada.',
    );
    expect(
      crear,
      contains('fechaServidor: FieldValue.serverTimestamp()'),
      reason: 'La fecha debe proceder del servidor.',
    );
  });
}
