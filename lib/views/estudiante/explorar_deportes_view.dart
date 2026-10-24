import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/detalle_deporte_dialog.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/estudiante/widgets/filtros_deportes.dart';
import 'package:saman_sports/views/home/widgets/deporte_card.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Catálogo de deportes del estudiante con búsqueda y filtros
/// (RF-02 y RF-03). Los cupos se actualizan en tiempo real.
class ExplorarDeportesView extends StatefulWidget {
  const ExplorarDeportesView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final ExplorarDeportesController controller;

  @override
  State<ExplorarDeportesView> createState() => _ExplorarDeportesViewState();
}

class _ExplorarDeportesViewState extends State<ExplorarDeportesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudianteExplorar,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.explorarDeportes,
      descripcion: AppStrings.explorarDeportesDescripcion,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FiltrosDeportes(controller: widget.controller),
            const SizedBox(height: AppSizes.space24),
            _Resultados(controller: widget.controller),
          ],
        ),
      ),
    );
  }
}

class _Resultados extends StatelessWidget {
  const _Resultados({required this.controller});

  final ExplorarDeportesController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    if (c.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MensajeError(texto: c.error!),
          const SizedBox(height: AppSizes.space16),
          BotonSecundario(texto: AppStrings.reintentar, onPressed: c.iniciar),
        ],
      );
    }

    if (c.cargando) {
      return const EtiquetaEjemplo(cargando: true);
    }

    final lista = c.deportesFiltrados;
    if (lista.isEmpty) {
      return EstadoVacio(
        icono: Icons.search_off,
        titulo: AppStrings.sinResultados,
        texto: AppStrings.sinResultadosTexto,
        textoAccion: c.hayFiltros ? AppStrings.limpiarFiltros : null,
        onAccion: c.hayFiltros ? c.limpiarFiltros : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${lista.length} ${AppStrings.disciplinasEncontradas}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (c.usandoEjemplo) const EtiquetaEjemplo(),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth < AppSizes.mobile
                ? 1
                : constraints.maxWidth < AppSizes.desktop
                ? 2
                : 3;
            final ancho =
                ((constraints.maxWidth - AppSizes.space12 * (columnas - 1)) /
                        columnas)
                    .floorToDouble();
            return Wrap(
              spacing: AppSizes.space12,
              runSpacing: AppSizes.space12,
              children: [
                for (final deporte in lista)
                  SizedBox(
                    width: ancho,
                    child: DeporteCard(
                      deporte: deporte,
                      onDetalles: () => mostrarDetalleDeporte(context, deporte),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
