import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/views/admin/widgets/selector_cancha_horario.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class DeporteFormDialog extends StatefulWidget {
  const DeporteFormDialog({
    super.key,
    required this.deportes,
    required this.entrenadores,
    this.deporte,
  });

  final AdminDeporteController deportes;
  final AdminEntrenadorController entrenadores;
  final Deporte? deporte;

  @override
  State<DeporteFormDialog> createState() => _DeporteFormDialogState();
}

class _DeporteFormDialogState extends State<DeporteFormDialog> {
  static const _iconos = [
    'futbol',
    'baloncesto',
    'tenis',
    'voleibol',
    'natacion',
    'running',
    'otro',
  ];

  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _cupos;
  late String _icono;
  String? _canchaId;
  String? _entrenadorUid;
  List<FranjaHorario> _franjas = [];

  @override
  void initState() {
    super.initState();
    final deporte = widget.deporte;
    _nombre = TextEditingController(text: deporte?.nombre ?? '');
    _descripcion = TextEditingController(text: deporte?.descripcion ?? '');
    _cupos = TextEditingController(text: '${deporte?.cupos ?? ''}');
    _icono = deporte?.icono ?? _iconos.first;
    _canchaId = deporte?.canchaId.isEmpty ?? true ? null : deporte?.canchaId;
    _entrenadorUid = deporte?.entrenadorUid.isEmpty ?? true
        ? null
        : deporte?.entrenadorUid;
    _franjas = [...?deporte?.horarios];
    if (_canchaId != null) widget.deportes.observarCancha(_canchaId);
  }

  @override
  void dispose() {
    widget.deportes.observarCancha(null);
    _nombre.dispose();
    _descripcion.dispose();
    _cupos.dispose();
    super.dispose();
  }

  bool _puedeGuardar() {
    if (widget.deportes.guardando || _canchaId == null || _franjas.isEmpty) {
      return false;
    }
    return widget.deportes.validarHorario(
          canchaId: _canchaId!,
          franjas: _franjas,
          ignorarDeporteId: widget.deporte?.id,
        ) ==
        null;
  }

  Future<void> _guardar() async {
    final cupos = int.tryParse(_cupos.text.trim()) ?? 0;
    final nombreEntrenador = _entrenadorUid == null
        ? ''
        : widget.entrenadores.entrenadoresActivos
              .firstWhere((item) => item.uid == _entrenadorUid)
              .nombreCompleto;
    final error = widget.deporte == null
        ? await widget.deportes.crearDeporte(
            nombre: _nombre.text,
            descripcion: _descripcion.text,
            icono: _icono,
            cupos: cupos,
            canchaId: _canchaId!,
            franjas: _franjas,
            entrenadorUid: _entrenadorUid ?? '',
            entrenadorNombre: nombreEntrenador,
          )
        : await widget.deportes.actualizarDeporte(
            deporte: widget.deporte!,
            nombre: _nombre.text,
            descripcion: _descripcion.text,
            icono: _icono,
            cupos: cupos,
            canchaId: _canchaId,
            franjas: _franjas,
          );
    if (!mounted || error != null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.deporte == null
            ? AppStrings.adminNuevoDeporte
            : AppStrings.editar,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: widget.deportes,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CampoTexto(label: AppStrings.nombre, controller: _nombre),
                  CampoTexto(
                    label: AppStrings.adminDescripcion,
                    controller: _descripcion,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _icono,
                    decoration: InputDecoration(
                      labelText: AppStrings.adminIcono,
                    ),
                    items: [
                      for (final icono in _iconos)
                        DropdownMenuItem(value: icono, child: Text(icono)),
                    ],
                    onChanged: (valor) {
                      if (valor != null) setState(() => _icono = valor);
                    },
                  ),
                  CampoTexto(
                    label: AppStrings.cupos,
                    controller: _cupos,
                    keyboardType: TextInputType.number,
                    helperText: widget.deporte == null
                        ? null
                        : '${AppStrings.adminInscritos}: ${widget.deporte!.inscritos}',
                  ),
                  const SizedBox(height: AppSizes.space12),
                  SelectorCanchaHorario(
                    canchas: widget.deportes.canchas,
                    canchaId: _canchaId,
                    franjas: _franjas,
                    reservasCancha: widget.deportes.reservasCancha,
                    ignorarRefId: widget.deporte?.id,
                    onCanchaChanged: (id) {
                      setState(() => _canchaId = id);
                      widget.deportes.observarCancha(id);
                    },
                    onFranjasChanged: (franjas) =>
                        setState(() => _franjas = franjas),
                  ),
                  if (_franjas.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppStrings.adminAyudaHorario),
                    ),
                  DropdownButtonFormField<String?>(
                    initialValue: _entrenadorUid,
                    decoration: InputDecoration(
                      labelText: AppStrings.entrenador,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.adminSinAsignar),
                      ),
                      for (final item
                          in widget.entrenadores.entrenadoresActivos)
                        DropdownMenuItem(
                          value: item.uid,
                          child: Text(item.nombreCompleto),
                        ),
                    ],
                    onChanged: (valor) =>
                        setState(() => _entrenadorUid = valor),
                  ),
                  if (widget.deportes.error != null)
                    Text(widget.deportes.error!),
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
          cargando: widget.deportes.guardando,
          onPressed: _puedeGuardar() ? _guardar : null,
        ),
      ],
    );
  }
}
