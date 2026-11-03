import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/services/exportacion/csv_asistencia.dart';

void main() {
  const alumno = AlumnoInscrito(
    inscripcionId: 'i1',
    uid: 'u1',
    nombre: 'Ana, "Pérez"',
    carnet: '20261001',
    correo: '=HYPERLINK("malicioso")',
  );
  test('CSV escapa comillas, separadores, fórmulas y agrega BOM real', () {
    final csv = generarCsvAsistencia(
      disciplina: 'Tenis',
      fecha: DateTime(2026, 10, 25),
      alumnos: [alumno],
      sesiones: [],
    );
    expect(csv.codeUnitAt(0), 0xFEFF);
    expect(csv, contains('"Ana, ""Pérez"""'));
    expect(csv, contains('"\'=HYPERLINK(""malicioso"")"'));
    expect(csv, contains('sin registrar'));
    expect(csv, contains('Sin registros'));
    expect(csv, contains('\r\n'));
  });
  test(
    'porcentaje excluye sesiones sin registro del alumno y posteriores a fecha',
    () {
      final csv = generarCsvAsistencia(
        disciplina: 'Tenis',
        fecha: DateTime(2026, 10, 25),
        alumnos: [alumno],
        sesiones: [
          SesionAsistencia(
            fecha: DateTime(2026, 10, 20),
            estados: {'i1': EstadoAsistencia.presente},
          ),
          SesionAsistencia(fecha: DateTime(2026, 10, 21), estados: {}),
          SesionAsistencia(
            fecha: DateTime(2026, 10, 25),
            estados: {'i1': EstadoAsistencia.ausente},
          ),
          SesionAsistencia(
            fecha: DateTime(2026, 10, 26),
            estados: {'i1': EstadoAsistencia.presente},
          ),
        ],
      );
      expect(csv, contains('"ausente","2","1","50.0%"'));
    },
  );
}
