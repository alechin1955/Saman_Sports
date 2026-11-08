import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/views/admin/widgets/selector_cancha_horario.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class EventoFormDialog extends StatefulWidget {
  const EventoFormDialog({super.key, required this.eventos, this.evento});

  final AdminEventoController eventos;
  final Evento? evento;

  @override
  State<EventoFormDialog> createState() => _EventoFormDialogState();
}

class _EventoFormDialogState extends State<EventoFormDialog> {
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late TipoEvento _tipo;
  String? _canchaId;
  String? _deporteId;
  String? _fecha;
  List<FranjaHorario> _franjas = [];

  @override
  void initState() {
    super.initState();
    final evento = widget.evento;
    _titulo = TextEditingController(text: evento?.titulo ?? '');
    _descripcion = TextEditingController(text: evento?.descripcion ?? '');
    _tipo = evento?.tipo ?? TipoEvento.evento;
    _canchaId = evento?.canchaId;
    _deporteId = evento?.deporteId;
    _fecha = evento?.fecha;
    if (evento != null) _franjas = [evento.franja];
    if (_canchaId != null) widget.eventos.observarCancha(_canchaId);
  }

  @override
  void dispose() {
    widget.eventos.observarCancha(null);
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  bool _puedeGuardar() {
    if (widget.eventos.guardando || _canchaId == null || _fecha == null) {
      return false;
    }
    if (_franjas.isEmpty) return false;
    return widget.eventos.validarEvento(
          canchaId: _canchaId!,
          fecha: _fecha!,
          horaInicio: _franjas.first.horaInicio,
          horaFin: _franjas.first.horaFin,
          ignorarEventoId: widget.evento?.id,
          deporteId: _deporteId,
        ) ==
        null;
  }

  Future<void> _guardar() async {
    final franja = _franjas.first;
    final error = widget.evento == null
        ? await widget.eventos.crearEvento(
            titulo: _titulo.text,
            tipo: _tipo,
            canchaId: _canchaId!,
            fecha: _fecha!,
            horaInicio: franja.horaInicio,
            horaFin: franja.horaFin,
            descripcion: _descripcion.text,
            deporteId: _deporteId,
            deporteNombre: _nombreDeporte(),
          )
        : await widget.eventos.actualizarEvento(
            evento: widget.evento!,
            titulo: _titulo.text,
            descripcion: _descripcion.text,
            canchaId: _canchaId,
            fecha: _fecha,
            horaInicio: franja.horaInicio,
            horaFin: franja.horaFin,
          );
    if (!mounted || error != null) return;
    Navigator.pop(context);
  }

  String? _nombreDeporte() {
    for (final deporte in widget.eventos.deportesActivos) {
      if (deporte.id == _deporteId) return deporte.nombre;
    }
    return widget.evento?.deporteNombre;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.evento == null ? AppStrings.adminNuevoEvento : AppStrings.editar,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: widget.eventos,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CampoTexto(label: AppStrings.nombre, controller: _titulo),
                  DropdownButtonFormField<String?>(
                    initialValue: _deporteId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.adminDisciplina,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.adminSinAsignar),
                      ),
                      for (final deporte in widget.eventos.deportesActivos)
                        DropdownMenuItem(
                          value: deporte.id,
                          child: Text(deporte.nombre),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _deporteId = valor),
                  ),
                  DropdownButtonFormField<TipoEvento>(
                    initialValue: _tipo,
                    decoration: InputDecoration(
                      labelText: AppStrings.adminTipo,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TipoEvento.partido,
                        child: Text(AppStrings.adminPartido),
                      ),
                      DropdownMenuItem(
                        value: TipoEvento.evento,
                        child: Text(AppStrings.adminEventoTipo),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) setState(() => _tipo = valor);
                    },
                  ),
                  CampoTexto(
                    label: AppStrings.adminDescripcion,
                    controller: _descripcion,
                  ),
                  SelectorCanchaHorario(
                    canchas: widget.eventos.canchas,
                    canchaId: _canchaId,
                    franjas: _franjas,
                    reservasCancha: widget.eventos.reservasCancha,
                    modoFecha: true,
                    fecha: _fecha,
                    ignorarRefId: widget.evento?.id,
                    onCanchaChanged: (id) {
                      setState(() => _canchaId = id);
                      widget.eventos.observarCancha(id);
                    },
                    onFechaChanged: (fecha) => setState(() => _fecha = fecha),
                    onFranjasChanged: (franjas) =>
                        setState(() => _franjas = franjas),
                  ),
                  if (_franjas.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppStrings.adminAyudaHorario),
                    ),
                  if (widget.eventos.error != null) Text(widget.eventos.error!),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        BotonSecundario(
          texto: AppStrings.cancelar,
          onPressed: () => Navigator.pop(context),
        ),
        BotonPrimario(
          texto: AppStrings.guardar,
          onPressed: _puedeGuardar() ? _guardar : null,
        ),
      ],
    );
  }
}
