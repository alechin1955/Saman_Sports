import 'package:saman_sports/models/reserva_horario.dart';

const List<String> abreviaturasDias = [
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom',
];

String minutosATexto(int minutos) {
  final horas = (minutos ~/ 60).toString().padLeft(2, '0');
  final resto = (minutos % 60).toString().padLeft(2, '0');
  return '$horas:$resto';
}

int? textoAMinutos(String hhmm) {
  final partes = hhmm.split(':');
  if (partes.length != 2) return null;
  final horas = int.tryParse(partes[0]);
  final minutos = int.tryParse(partes[1]);
  if (horas == null || minutos == null) return null;
  if (horas < 0 || horas > 24 || minutos < 0 || minutos > 59) return null;
  if (horas == 24 && minutos != 0) return null;
  return horas * 60 + minutos;
}

String? validarFranja(FranjaHorario franja) {
  if (franja.dia < 1 || franja.dia > 7) {
    return 'El día debe estar entre 1 y 7.';
  }
  if (franja.horaInicio < 0) {
    return 'La hora de inicio no puede ser negativa.';
  }
  if (franja.horaFin > 1440) {
    return 'La hora de fin no puede pasar de las 24:00.';
  }
  if (franja.horaInicio >= franja.horaFin) {
    return 'La hora de inicio debe ser menor que la de fin.';
  }
  if (franja.horaFin - franja.horaInicio < 30) {
    return 'La franja debe durar al menos 30 minutos.';
  }
  return null;
}

bool seSolapan(int iniA, int finA, int iniB, int finB) {
  return iniA < finB && iniB < finA;
}

bool reservasChocan(ReservaHorario a, ReservaHorario b) {
  if (a.canchaId != b.canchaId || !a.activa || !b.activa) return false;
  if (!seSolapan(a.horaInicio, a.horaFin, b.horaInicio, b.horaFin)) {
    return false;
  }
  final fechaA = _fechaConValor(a.fecha);
  final fechaB = _fechaConValor(b.fecha);
  if (fechaA == null && fechaB == null) return a.dia == b.dia;
  if (fechaA != null && fechaB != null) return fechaA == fechaB;
  final semanal = fechaA == null ? a : b;
  final puntual = fechaA == null ? b : a;
  return DateTime.tryParse(puntual.fecha!)?.weekday == semanal.dia;
}

ReservaHorario? buscarChoque({
  required List<ReservaHorario> nuevas,
  required List<ReservaHorario> existentes,
  String? ignorarRefId,
}) {
  for (var i = 0; i < nuevas.length; i++) {
    for (var j = 0; j < i; j++) {
      if (reservasChocan(nuevas[i], nuevas[j])) return nuevas[i];
    }
  }
  for (final nueva in nuevas) {
    for (final existente in existentes) {
      if (ignorarRefId != null && existente.refId == ignorarRefId) continue;
      if (reservasChocan(nueva, existente)) return existente;
    }
  }
  return null;
}

String textoHorario(List<FranjaHorario> franjas, {String? cancha}) {
  if (franjas.isEmpty) return '';
  final ordenadas = [...franjas]..sort((a, b) => a.dia.compareTo(b.dia));
  final grupos = <String, List<int>>{};
  final orden = <String>[];
  for (final franja in ordenadas) {
    final clave = '${franja.horaInicio}-${franja.horaFin}';
    if (grupos[clave] == null) {
      grupos[clave] = [];
      orden.add(clave);
    }
    grupos[clave]!.add(franja.dia);
  }
  final partes = orden.map((clave) {
    final horas = clave.split('-');
    final inicio = int.parse(horas[0]);
    final fin = int.parse(horas[1]);
    final dias = _unirDias(grupos[clave]!);
    return '$dias ${minutosATexto(inicio)}–${minutosATexto(fin)}';
  });
  final texto = partes.join(' · ');
  if (cancha == null || cancha.trim().isEmpty) return texto;
  return '$texto · $cancha';
}

String mensajeChoque(ReservaHorario reserva) {
  final cuando = _fechaConValor(reserva.fecha) == null
      ? abreviaturasDias[reserva.dia - 1]
      : _fechaVisible(reserva.fecha!);
  final inicio = minutosATexto(reserva.horaInicio);
  final fin = minutosATexto(reserva.horaFin);
  return 'La cancha ${reserva.canchaNombre} ya está ocupada el $cuando '
      'de $inicio a $fin por ${reserva.refNombre} (${reserva.tipo.valor}).';
}

String? _fechaConValor(String? fecha) {
  if (fecha == null || fecha.isEmpty) return null;
  return fecha;
}

String _fechaVisible(String fecha) {
  final partes = fecha.split('-');
  if (partes.length != 3) return fecha;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

String _unirDias(List<int> dias) {
  final nombres = dias.map((dia) => abreviaturasDias[dia - 1]).toList();
  if (nombres.length == 1) return nombres.first;
  if (nombres.length == 2) return '${nombres[0]} y ${nombres[1]}';
  return '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
}
