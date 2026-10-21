import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_publico.dart';
import 'package:saman_sports/models/resena.dart';

class DatosEjemplo {
  static final List<Deporte> deportes = [
    const Deporte(id: 'ej-futbol', nombre: 'Fútbol', descripcion: 'Entrenamientos en la cancha principal y partidos internos.', icono: 'futbol', horario: 'Lun y mié, 4:00 p. m.', cupos: 22, inscritos: 18, entrenadorNombre: 'Carlos Méndez'),
    const Deporte(id: 'ej-baloncesto', nombre: 'Baloncesto', descripcion: 'Práctica de fundamentos, tiros y juego en equipo.', icono: 'baloncesto', horario: 'Mar y jue, 5:00 p. m.', cupos: 15, inscritos: 14, entrenadorNombre: 'Laura Pérez'),
    const Deporte(id: 'ej-tenis', nombre: 'Tenis', descripcion: 'Clases para principiantes y seguimiento de técnica.', icono: 'tenis', horario: 'Vie, 3:00 p. m.', cupos: 10, inscritos: 4, entrenadorNombre: 'Andrés Rojas'),
    const Deporte(id: 'ej-voleibol', nombre: 'Voleibol', descripcion: 'Saque, recepción y trabajo de equipo en gimnasio.', icono: 'voleibol', horario: 'Lun y vie, 6:00 p. m.', cupos: 16, inscritos: 9, entrenadorNombre: 'Ana Torres'),
    const Deporte(id: 'ej-natacion', nombre: 'Natación', descripcion: 'Resistencia y técnica en la piscina universitaria.', icono: 'natacion', horario: 'Mar y jue, 7:00 a. m.', cupos: 12, inscritos: 12, entrenadorNombre: 'Carlos Méndez'),
    const Deporte(id: 'ej-running', nombre: 'Running', descripcion: 'Salidas grupales por el campus y plan de ritmo.', icono: 'running', horario: 'Sáb, 7:30 a. m.', cupos: 30, inscritos: 11, entrenadorNombre: 'Laura Pérez'),
  ];

  static const List<EntrenadorPublico> entrenadores = [
    EntrenadorPublico(id: 'ej-1', nombre: 'Carlos', apellido: 'Méndez', disciplina: 'Fútbol', descripcion: 'Acompaña el trabajo táctico y la condición física.'),
    EntrenadorPublico(id: 'ej-2', nombre: 'Laura', apellido: 'Pérez', disciplina: 'Baloncesto', descripcion: 'Enfoca la práctica en fundamentos y juego colectivo.'),
    EntrenadorPublico(id: 'ej-3', nombre: 'Andrés', apellido: 'Rojas', disciplina: 'Tenis', descripcion: 'Corrige técnica de golpe y desplazamiento.'),
    EntrenadorPublico(id: 'ej-4', nombre: 'Ana', apellido: 'Torres', disciplina: 'Voleibol', descripcion: 'Organiza rotaciones y trabajo de recepción.'),
  ];

  static final List<Resena> resenas = [
    Resena(id: 'ej-r1', autorUid: 'ej', autorNombre: 'María G.', disciplina: 'Fútbol', deporteId: 'ej-futbol', estrellas: 5, comentario: 'Los horarios son claros y el grupo se organiza bien.', fecha: DateTime(2026, 3, 12)),
    Resena(id: 'ej-r2', autorUid: 'ej', autorNombre: 'Luis R.', disciplina: 'Natación', deporteId: 'ej-natacion', estrellas: 4, comentario: 'Buena guía para mejorar la técnica sin perder el ritmo.', fecha: DateTime(2026, 2, 2)),
    Resena(id: 'ej-r3', autorUid: 'ej', autorNombre: 'Sofía P.', disciplina: 'Tenis', deporteId: 'ej-tenis', estrellas: 5, comentario: 'Las clases son ordenadas y es fácil reservar cupo.', fecha: DateTime(2026, 1, 20)),
    Resena(id: 'ej-r4', autorUid: 'ej', autorNombre: 'Diego A.', disciplina: 'Running', deporteId: 'ej-running', estrellas: 4, comentario: 'Las salidas del sábado ayudan a mantener la constancia.', fecha: DateTime(2026, 4, 5)),
  ];
}
