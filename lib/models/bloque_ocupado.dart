import 'package:saman_sports/models/reserva_horario.dart';

class BloqueOcupado {
  const BloqueOcupado({
    required this.canchaId,
    required this.canchaNombre,
    required this.dia,
    required this.fecha,
    required this.inicio,
    required this.fin,
    required this.tipo,
    required this.titulo,
  });

  final String canchaId;
  final String canchaNombre;
  final int dia;
  final String fecha;
  final int inicio;
  final int fin;
  final TipoReserva tipo;
  final String titulo;
}

class FranjaLibre {
  const FranjaLibre({required this.inicio, required this.fin});

  final int inicio;
  final int fin;
}
