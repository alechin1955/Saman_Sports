import 'package:flutter/widgets.dart';

/// Una opción del menú lateral de un panel por rol.
/// Cada rol define su lista de opciones en un solo archivo
/// (por ejemplo, lib/views/estudiante/opciones_estudiante.dart).
class OpcionPanel {
  const OpcionPanel({
    required this.icono,
    required this.texto,
    required this.ruta,
  });

  final IconData icono;
  final String texto;
  final String ruta;
}
