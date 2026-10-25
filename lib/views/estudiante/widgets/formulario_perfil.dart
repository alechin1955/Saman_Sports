import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/validators.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

/// Formulario de "Mi perfil": nombre, apellido y teléfono.
/// Valida con Validators y guarda a través de EstudianteController.
class FormularioPerfil extends StatefulWidget {
  const FormularioPerfil({
    super.key,
    required this.controller,
    required this.estudiante,
  });

  final EstudianteController controller;
  final Estudiante estudiante;

  @override
  State<FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<FormularioPerfil> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(
    text: widget.estudiante.nombre,
  );
  late final TextEditingController _apellido = TextEditingController(
    text: widget.estudiante.apellido,
  );
  late final TextEditingController _telefono = TextEditingController(
    text: widget.estudiante.telefono,
  );

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.controller.actualizarPerfil(
      nombre: _nombre.text,
      apellido: _apellido.text,
      telefono: _telefono.text,
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text(AppStrings.perfilActualizado),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campoNombre = CampoTexto(
      controller: _nombre,
      label: AppStrings.nombre,
      icono: Icons.person_outline,
      textInputAction: TextInputAction.next,
      validator: Validators.nombre,
    );
    final campoApellido = CampoTexto(
      controller: _apellido,
      label: AppStrings.apellido,
      textInputAction: TextInputAction.next,
      validator: Validators.apellido,
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.datosPersonales, style: AppTextStyles.subtitle),
            const SizedBox(height: AppSizes.space16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= AppSizes.formMaxWidth) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: campoNombre),
                      const SizedBox(width: AppSizes.space16),
                      Expanded(child: campoApellido),
                    ],
                  );
                }
                return Column(
                  children: [
                    campoNombre,
                    const SizedBox(height: AppSizes.space16),
                    campoApellido,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.space16),
            CampoTexto(
              controller: _telefono,
              label: AppStrings.telefono,
              hint: AppStrings.hintTelefono,
              icono: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: Validators.telefono,
              onFieldSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: AppSizes.space24),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final c = widget.controller;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (c.error != null) ...[
                      MensajeError(texto: c.error!),
                      const SizedBox(height: AppSizes.space16),
                    ],
                    BotonPrimario(
                      texto: AppStrings.guardarCambios,
                      cargando: c.guardando,
                      anchoCompleto: true,
                      onPressed: _guardar,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
