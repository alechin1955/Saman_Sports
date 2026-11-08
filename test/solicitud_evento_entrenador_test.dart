import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/utils/solicitud_evento_entrenador.dart';
import 'package:saman_sports/models/reserva_horario.dart';

void main() {
  final deporte = <String, dynamic>{
    'id': 'tenis',
    'nombre': 'Tenis',
    'canchaId': 'c1',
    'entrenadorUid': 'entrenador-1',
    'activo': true,
  };
  final cancha = <String, dynamic>{
    'id': 'c1',
    'nombre': 'Cancha oficial',
    'ubicacion': 'Edificio deportivo',
    'activa': true,
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
        'canchaId': 'c1',
        'canchaNombre': 'Cancha manipulada',
        'capacidad': 24,
        'descripcion': ' Cierre de semestre ',
        'estado': 'aprobado',
        'creadoPorUid': 'atacante',
        'campoExtra': 'no permitido',
      },
      entrenadorUid: 'entrenador-1',
      deporte: deporte,
      cancha: cancha,
      reservasCancha: const [],
      ahora: DateTime(2026, 11, 7),
    );

    expect(solicitud['estado'], 'pendiente');
    expect(solicitud['creadoPorUid'], 'entrenador-1');
    expect(solicitud['tipo'], 'evento');
    expect(solicitud['canchaId'], 'c1');
    expect(solicitud['canchaNombre'], 'Cancha oficial');
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
        cancha: cancha,
        reservasCancha: const [],
        ahora: DateTime(2026, 11, 7),
      ),
      throwsStateError,
    );
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: _datosValidos,
        entrenadorUid: 'entrenador-1',
        deporte: {...deporte, 'activo': false},
        cancha: cancha,
        reservasCancha: const [],
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
        cancha: cancha,
        reservasCancha: const [],
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
        cancha: cancha,
        reservasCancha: const [],
        ahora: DateTime(2026, 1, 7),
      ),
      throwsStateError,
    );
  });

  test('rechaza una cancha inactiva o con choque de horario', () {
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: _datosValidos,
        entrenadorUid: 'entrenador-1',
        deporte: deporte,
        cancha: {...cancha, 'activa': false},
        reservasCancha: const [],
        ahora: DateTime(2026, 11, 7),
      ),
      throwsStateError,
    );
    expect(
      () => construirSolicitudEventoEntrenador(
        datos: _datosValidos,
        entrenadorUid: 'entrenador-1',
        deporte: deporte,
        cancha: cancha,
        reservasCancha: const [
          ReservaHorario(
            id: 'r1',
            canchaId: 'c1',
            canchaNombre: 'Cancha oficial',
            dia: 2,
            horaInicio: 840,
            horaFin: 960,
            fecha: '2026-11-10',
            tipo: TipoReserva.evento,
            refId: 'e1',
            refNombre: 'Evento aprobado',
            activa: true,
          ),
        ],
        ahora: DateTime(2026, 11, 7),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'mensaje',
          contains('Evento aprobado'),
        ),
      ),
    );
  });
}

const _datosValidos = <String, dynamic>{
  'titulo': 'Torneo interno',
  'deporteId': 'tenis',
  'fecha': '2026-11-10',
  'horaInicio': 840,
  'horaFin': 960,
  'canchaId': 'c1',
  'capacidad': 24,
  'descripcion': 'Cierre de semestre',
};
