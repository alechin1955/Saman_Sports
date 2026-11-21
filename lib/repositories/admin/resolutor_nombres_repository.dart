import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

abstract interface class ResolutorNombresAdmin {
  /// Texto legible del documento o null si no existe o no se pudo leer.
  Future<String?> nombre(String coleccion, String id);
}

class FirebaseResolutorNombresAdmin implements ResolutorNombresAdmin {
  @override
  Future<String?> nombre(String coleccion, String id) async {
    final datos = await FirebaseServices.leerDocumentoAdmin(
      coleccion: coleccion,
      id: id,
    );
    if (datos == null) return null;
    return switch (coleccion) {
      'usuarios' => _persona(datos),
      'deportes' || 'canchas' => _texto(datos['nombre']),
      'eventos' => _texto(datos['titulo']),
      'pagos' => AppStrings.txPagoPeriodo('${datos['periodo'] ?? ''}'),
      'resenas' => AppStrings.txResenaDe(
        '${datos['autorNombre'] ?? ''}',
        '${datos['disciplina'] ?? ''}',
      ),
      'tickets' => AppStrings.txTicketDe('${datos['asunto'] ?? ''}'),
      _ => null,
    };
  }

  String? _texto(dynamic valor) {
    final texto = '$valor'.trim();
    return texto.isEmpty ? null : texto;
  }

  String? _persona(Map<String, dynamic> datos) {
    final nombre = '${datos['nombre'] ?? ''}'.trim();
    final apellido = '${datos['apellido'] ?? ''}'.trim();
    final completo = '$nombre $apellido'.trim();
    if (completo.isNotEmpty) return completo;
    final correo = '${datos['correo'] ?? ''}'.trim();
    return correo.isEmpty ? null : correo;
  }
}
