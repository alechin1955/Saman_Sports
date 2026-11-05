import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class CanchaFormDialog extends StatefulWidget {
  const CanchaFormDialog({super.key, required this.deportes, this.cancha});

  final AdminDeporteController deportes;
  final Cancha? cancha;

  @override
  State<CanchaFormDialog> createState() => _CanchaFormDialogState();
}

class _CanchaFormDialogState extends State<CanchaFormDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _ubicacion;
  late final TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.cancha?.nombre ?? '');
    _ubicacion = TextEditingController(text: widget.cancha?.ubicacion ?? '');
    _descripcion = TextEditingController(
      text: widget.cancha?.descripcion ?? '',
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _ubicacion.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final error = widget.cancha == null
        ? await widget.deportes.crearCancha(
            nombre: _nombre.text,
            ubicacion: _ubicacion.text,
            descripcion: _descripcion.text,
          )
        : await widget.deportes.actualizarCancha(
            cancha: widget.cancha!,
            nombre: _nombre.text,
            ubicacion: _ubicacion.text,
            descripcion: _descripcion.text,
          );
    if (!mounted || error != null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.cancha == null ? AppStrings.adminNuevaCancha : AppStrings.editar,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampoTexto(label: AppStrings.nombre, controller: _nombre),
          CampoTexto(label: AppStrings.adminUbicacion, controller: _ubicacion),
          CampoTexto(
            label: AppStrings.adminDescripcion,
            controller: _descripcion,
          ),
        ],
      ),
      actions: [
        BotonSecundario(
          texto: AppStrings.cancelar,
          onPressed: () => Navigator.pop(context),
        ),
        BotonPrimario(texto: AppStrings.guardar, onPressed: _guardar),
      ],
    );
  }
}
