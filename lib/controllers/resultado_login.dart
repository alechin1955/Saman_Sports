enum DestinoLogin { estudiante, entrenador, administrador }

enum TipoResultadoRol { valido, sinRol, error }

class ResultadoRol {
  const ResultadoRol({required this.tipo, this.destino});

  final TipoResultadoRol tipo;
  final DestinoLogin? destino;
}
