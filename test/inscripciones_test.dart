import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/deporte.dart';

Map<String, dynamic> inscripcion(
  String id,
  String deporteId,
  String estado, {
  int dia = 1,
}) {
  return {
    'id': id,
    'estudianteUid': 'u1',
    'deporteId': deporteId,
    'deporteNombre': 'Deporte $deporteId',
    'estado': estado,
    'fecha': DateTime(2026, 11, dia),
  };
}

const futbol = Deporte(
  id: 'd1',
  nombre: 'Fútbol',
  descripcion: '',
  icono: 'futbol',
  horario: '',
  cupos: 10,
  inscritos: 3,
  entrenadorNombre: '',
);

void main() {
  group('InscripcionesController', () {
    late StreamController<List<Map<String, dynamic>>> fuente;
    late List<String> llamadas;

    InscripcionesController crear({
      AuthResponse? respuesta,
      String? Function()? uid,
    }) {
      fuente = StreamController<List<Map<String, dynamic>>>();
      llamadas = [];
      return InscripcionesController(
        uidActual: uid ?? () => 'u1',
        origen: (_) => fuente.stream,
        inscribir: (id) async {
          llamadas.add('inscribir $id');
          return respuesta ?? AuthResponse(isSuccess: true);
        },
        cancelar: (id) async {
          llamadas.add('cancelar $id');
          return respuesta ?? AuthResponse(isSuccess: true);
        },
      );
    }

    test('ordena de la más nueva a la más vieja y separa las activas',
        () async {
      final c = crear()..iniciar();
      fuente.add([
        inscripcion('a', 'd1', 'pendiente', dia: 2),
        inscripcion('b', 'd2', 'cancelada', dia: 5),
        inscripcion('c', 'd3', 'confirmada', dia: 3),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(c.cargando, isFalse);
      expect(c.inscripciones.map((i) => i.id), ['b', 'c', 'a']);
      expect(c.activas.map((i) => i.id), ['c', 'a']);
      expect(c.activaEn('d1')?.id, 'a');
      expect(c.activaEn('d2'), isNull);
      c.dispose();
    });

    test('sin sesión muestra el error de sesión', () {
      final c = crear(uid: () => null)..iniciar();
      expect(c.error, AppStrings.sesionNoIniciada);
      c.dispose();
    });

    test('se inscribe en un deporte con cupo', () async {
      final c = crear()..iniciar();
      fuente.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(c.puedeInscribirse(futbol), isTrue);
      expect(await c.inscribirse(futbol), isNull);
      expect(llamadas, ['inscribir d1']);
      c.dispose();
    });

    test('no deja inscribirse dos veces en el mismo deporte', () async {
      final c = crear()..iniciar();
      fuente.add([inscripcion('a', 'd1', 'pendiente')]);
      await Future<void>.delayed(Duration.zero);

      expect(c.puedeInscribirse(futbol), isFalse);
      expect(await c.inscribirse(futbol), AppStrings.inscripcionYaExiste);
      expect(llamadas, isEmpty);
      c.dispose();
    });

    test('no deja inscribirse si no quedan cupos', () async {
      final c = crear()..iniciar();
      fuente.add([]);
      await Future<void>.delayed(Duration.zero);

      const lleno = Deporte(
        id: 'd9',
        nombre: 'Natación',
        descripcion: '',
        icono: 'natacion',
        horario: '',
        cupos: 5,
        inscritos: 5,
        entrenadorNombre: '',
      );
      expect(await c.inscribirse(lleno), AppStrings.inscripcionSinCupos);
      expect(llamadas, isEmpty);
      c.dispose();
    });

    test('devuelve el mensaje de error de la fachada', () async {
      final c = crear(
        respuesta: AuthResponse(
          isSuccess: false,
          errorMessage: AppStrings.inscripcionCuentaInactiva,
        ),
      )..iniciar();
      fuente.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(await c.inscribirse(futbol), AppStrings.inscripcionCuentaInactiva);
      expect(c.procesando, isFalse);
      c.dispose();
    });
  });
}