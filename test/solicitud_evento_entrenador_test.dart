import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/utils/solicitud_evento_entrenador.dart';

void main() {
  final deporte = <String, dynamic>{
    'id': 'tenis',
    'nombre': 'Tenis',
    'canchaId': 'c1',
    'entrenadorUid': 'entrenador-1',
    'activo': true,
  };

  test('fuerza estado, UID y campos permitidos en la frontera Firebase', () {
    final solicitud = construirSolicitudEventoEntrenador(
      datos: {
        'titulo': ' Torneo interno ',
        'tipo': 'partido',
        'deporteId': 'tenis',
        'fecha': '2026-11-10',
        'horaInicio': 840,
        'horaFin': 960,
        'ubicacion': 'Cancha 1',
        'capacidad': 24,
        'descripcion': ' Cierre de semestre ',
        'estado': 'aprobado',
        'creadoPorUid': 'atacante',
        'campoExtra': 'no permitido',
      },
      entrenadorUid: 'entrenador-1',
      deporte: deporte,
      ahora: DateTime(2026, 11, 7),
    );

    expect(solicitud['estado'], 'pendiente');
    expect(solicitud['creadoPorUid'], 'entrenador-1');
    expect(solicitud['tipo'], 'evento');
    expect(solicitud['horaInicio'], 840);
    expect(solicitud['descripcion'], 'Cierre de semestre');
    expect(solicitud, isNot(contains('campoExtra')));
  });

  test('rechaza una disciplina ajena o inactiva', () {
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: _datosValidos,
        entrenadorUid: 'otro-entrenador',
        deporte: deporte,
        ahora: DateTime(2026, 11, 7),
      ),
      throwsStateError,
    );
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: _datosValidos,
        entrenadorUid: 'entrenador-1',
        deporte: {...deporte, 'activo': false},
        ahora: DateTime(2026, 11, 7),
      ),
      throwsStateError,
    );
  });

  test('rechaza horas enteras que no estén expresadas en minutos', () {
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: {..._datosValidos, 'horaInicio': 14, 'horaFin': 16},
        entrenadorUid: 'entrenador-1',
        deporte: deporte,
        ahora: DateTime(2026, 11, 7),
      ),
      throwsStateError,
    );
  });

  test('rechaza fechas inexistentes aunque tengan formato ISO', () {
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: {..._datosValidos, 'fecha': '2026-02-31'},
        entrenadorUid: 'entrenador-1',
        deporte: deporte,
        ahora: DateTime(2026, 1, 7),
      ),
      throwsStateError,
    );
  });
}

const _datosValidos = <String, dynamic>{
  'titulo': 'Torneo interno',
  'deporteId': 'tenis',
  'fecha': '2026-11-10',
  'horaInicio': 840,
  'horaFin': 960,
  'ubicacion': 'Cancha 1',
  'capacidad': 24,
  'descripcion': 'Cierre de semestre',
};
