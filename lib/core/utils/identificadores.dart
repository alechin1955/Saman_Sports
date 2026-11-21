import 'package:saman_sports/core/constants/app_strings.dart';

String cedulaNormalizada(String valor) => valor.trim().toUpperCase();

String carnetNormalizado(String valor) => valor.trim();

String idIdentificador(String tipo, String valor) {
  final normalizado = tipo == 'cedula'
      ? cedulaNormalizada(valor)
      : carnetNormalizado(valor);
  return '${tipo}_$normalizado';
}

class AlumnoIdentificador {
  const AlumnoIdentificador({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.carnet,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String cedula;
  final String carnet;
}

class PlanIdentificadores {
  const PlanIdentificadores({required this.crear, required this.informe});

  final List<({String id, String tipo, String uid})> crear;
  final List<String> informe;
}

String nombreIdentificador(String nombre, String apellido) {
  final completo = '${nombre.trim()} ${apellido.trim()}'.trim();
  return completo.isEmpty ? AppStrings.adminEstudianteSinNombre : completo;
}

/// Decide qué índices faltan, cuáles ya son propios y cuáles están ocupados
/// por otro estudiante. No escribe en Firebase.
PlanIdentificadores planificarIdentificadores({
  required List<AlumnoIdentificador> alumnos,
  required Map<String, String> ocupados,
}) {
  final asignados = Map<String, String>.from(ocupados);
  final nombres = {
    for (final alumno in alumnos)
      alumno.uid: nombreIdentificador(alumno.nombre, alumno.apellido),
  };
  final crear = <({String id, String tipo, String uid})>[];
  final duplicados = <String>[];
  final sinIndice = <String>[];
  final duplicadosVistos = <String>{};

  String nombreDe(String uid) => nombres[uid] ?? AppStrings.adminEstudianteSinNombre;

  for (final alumno in alumnos) {
    final cedula = cedulaNormalizada(alumno.cedula);
    final carnet = carnetNormalizado(alumno.carnet);
    var cedulaPropia = false;
    var carnetPropio = false;
    for (final item in [('cedula', cedula), ('carnet', carnet)]) {
      if (item.$2.isEmpty) continue;
      final id = idIdentificador(item.$1, item.$2);
      final dueno = asignados[id];
      if (dueno == null) {
        asignados[id] = alumno.uid;
        crear.add((id: id, tipo: item.$1, uid: alumno.uid));
        if (item.$1 == 'cedula') cedulaPropia = true;
        if (item.$1 == 'carnet') carnetPropio = true;
        continue;
      }
      if (dueno == alumno.uid) {
        if (item.$1 == 'cedula') cedulaPropia = true;
        if (item.$1 == 'carnet') carnetPropio = true;
        continue;
      }
      if (duplicadosVistos.add(id)) {
        duplicados.add(
          AppStrings.adminDuplicadoIdentificador(
            item.$1 == 'cedula' ? AppStrings.cedula : AppStrings.carnet,
            item.$2,
            nombreDe(dueno),
            nombreDe(alumno.uid),
          ),
        );
      }
    }
    if (cedula.isEmpty || !cedulaPropia || carnet.isEmpty || !carnetPropio) {
      sinIndice.add(
        AppStrings.adminEstudianteSinIndice(
          nombreDe(alumno.uid),
          _motivoSinIndice(
            cedula: cedula,
            carnet: carnet,
            cedulaPropia: cedulaPropia,
            carnetPropio: carnetPropio,
          ),
        ),
      );
    }
  }

  if (duplicados.isEmpty && sinIndice.isEmpty) {
    return PlanIdentificadores(crear: crear, informe: const []);
  }
  return PlanIdentificadores(
    crear: crear,
    informe: [
      if (duplicados.isNotEmpty) AppStrings.adminDuplicadosIdentificador,
      ...duplicados,
      if (sinIndice.isNotEmpty) AppStrings.adminSinIndiceIdentificador,
      ...sinIndice,
    ],
  );
}

String _motivoSinIndice({
  required String cedula,
  required String carnet,
  required bool cedulaPropia,
  required bool carnetPropio,
}) {
  final faltan = <String>[
    if (cedula.isEmpty || !cedulaPropia) AppStrings.cedula,
    if (carnet.isEmpty || !carnetPropio) AppStrings.carnet,
  ];
  return faltan.join(', ');
}
