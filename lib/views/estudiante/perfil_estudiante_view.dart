import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/datos_cuenta_card.dart';
import 'package:saman_sports/views/estudiante/widgets/formulario_perfil.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Página de perfil del estudiante (requisito del Hito 2).
/// Muestra los datos de la cuenta y permite editar nombre, apellido y teléfono.
class PerfilEstudianteView extends StatefulWidget {
  const PerfilEstudianteView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final EstudianteController controller;

  @override
  State<PerfilEstudianteView> createState() => _PerfilEstudianteViewState();
}

class _PerfilEstudianteViewState extends State<PerfilEstudianteView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudiantePerfil,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.miPerfil,
      descripcion: AppStrings.miPerfilDescripcion,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          final estudiante = c.estudiante;

          if (c.error != null && estudiante == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MensajeError(texto: c.error!),
                const SizedBox(height: AppSizes.space16),
                BotonSecundario(
                  texto: AppStrings.reintentar,
                  onPressed: c.cargarPerfil,
                ),
              ],
            );
          }

          if (c.cargando || estudiante == null) {
            return const EtiquetaEjemplo(cargando: true);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final formulario = FormularioPerfil(
                key: ValueKey(estudiante.uid),
                controller: c,
                estudiante: estudiante,
              );
              final cuenta = DatosCuentaCard(estudiante: estudiante);

              if (constraints.maxWidth >= AppSizes.perfilDosColumnas) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: formulario),
                    const SizedBox(width: AppSizes.space24),
                    Expanded(flex: 2, child: cuenta),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cuenta,
                  const SizedBox(height: AppSizes.space24),
                  formulario,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
