import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/perfil_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class EditarPerfilEntrenadorDialog extends StatefulWidget {
  const EditarPerfilEntrenadorDialog({
    super.key,
    required this.controller,
    required this.perfil,
  });

  final PerfilEntrenadorController controller;
  final PerfilEntrenador perfil;

  @override
  State<EditarPerfilEntrenadorDialog> createState() =>
      _EditarPerfilEntrenadorDialogState();
}

class _EditarPerfilEntrenadorDialogState
    extends State<EditarPerfilEntrenadorDialog> {
  late final TextEditingController _telefono = TextEditingController(
    text: widget.perfil.telefono,
  );
  late final TextEditingController _biografia = TextEditingController(
    text: widget.perfil.biografia,
  );
  late final TextEditingController _anos = TextEditingController(
    text: '${widget.perfil.anosExperiencia}',
  );
  late final TextEditingController _certificaciones = TextEditingController(
    text: widget.perfil.certificaciones.join('\n'),
  );

  @override
  void dispose() {
    _telefono.dispose();
    _biografia.dispose();
    _anos.dispose();
    _certificaciones.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final ok = await widget.controller.guardarPerfil(
      telefono: _telefono.text,
      biografia: _biografia.text,
      anosExperiencia: int.tryParse(_anos.text.trim()) ?? -1,
      certificaciones: _certificaciones.text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
    if (!mounted || !ok) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.entEditarPerfil),
      content: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CampoTexto(
                  label: AppStrings.telefono,
                  controller: _telefono,
                ),
                CampoTexto(
                  label: AppStrings.entBiografia,
                  controller: _biografia,
                ),
                CampoTexto(
                  label: AppStrings.adminAnosExperiencia,
                  controller: _anos,
                  keyboardType: TextInputType.number,
                ),
                CampoTexto(
                  label: AppStrings.entCertificaciones,
                  controller: _certificaciones,
                ),
                if (widget.controller.error != null)
                  MensajeError(texto: widget.controller.error!),
              ],
            ),
          );
        },
      ),
      actions: [
        BotonSecundario(
          texto: AppStrings.cancelar,
          onPressed: () => Navigator.pop(context, false),
        ),
        BotonPrimario(texto: AppStrings.guardar, onPressed: _guardar),
      ],
    );
  }
}
