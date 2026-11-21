import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/cambiar_clave_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class CambiarClaveDialog extends StatefulWidget {
  const CambiarClaveDialog({super.key, this.controller});

  final CambiarClaveController? controller;

  @override
  State<CambiarClaveDialog> createState() => _CambiarClaveDialogState();
}

class _CambiarClaveDialogState extends State<CambiarClaveDialog> {
  late final CambiarClaveController _controller =
      widget.controller ?? CambiarClaveController();
  late final bool _propio = widget.controller == null;
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    if (_propio) _controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final ok = await _controller.guardar(
      actual: _actual.text,
      nueva: _nueva.text,
      confirmar: _confirmar.text,
    );
    if (!mounted || !ok) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.cambiarClave),
      content: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampoTexto(
                label: AppStrings.claveActual,
                controller: _actual,
                esContrasena: true,
              ),
              CampoTexto(
                label: AppStrings.claveNueva,
                controller: _nueva,
                esContrasena: true,
              ),
              CampoTexto(
                label: AppStrings.confirmarContrasena,
                controller: _confirmar,
                esContrasena: true,
              ),
              if (_controller.error != null)
                MensajeError(texto: _controller.error!),
            ],
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
