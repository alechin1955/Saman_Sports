import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/historial_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/formato_fecha.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_inscripcion_chip.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Historial del estudiante (RF-14): todas sus inscripciones, también las
/// canceladas, con el porcentaje de asistencia que registró el entrenador.
class HistorialEstudianteView extends StatefulWidget {
  const HistorialEstudianteView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final HistorialController controller;

  @override
  State<HistorialEstudianteView> createState() =>
      _HistorialEstudianteViewState();
}

class _HistorialEstudianteViewState extends State<HistorialEstudianteView> {
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
      rutaActiva: AppRoutes.estudianteHistorial,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.historial,
      descripcion: AppStrings.historialDescripcion,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          if (c.error != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MensajeError(texto: c.error!),
                const SizedBox(height: AppSizes.space16),
                BotonSecundario(
                  texto: AppStrings.reintentar,
                  onPressed: c.iniciar,
                ),
              ],
            );
          }
          if (c.cargando) return const EtiquetaEjemplo(cargando: true);
          if (c.historial.isEmpty) {
            return EstadoVacio(
              icono: Icons.history,
              titulo: AppStrings.sinHistorial,
              texto: AppStrings.sinHistorialTexto,
              textoAccion: AppStrings.explorarDeportes,
              onAccion: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.estudianteExplorar,
              ),
            );
          }
          final general = c.general;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSizes.space12,
                runSpacing: AppSizes.space12,
                children: [
                  _Indicador(
                    icono: Icons.event_note_outlined,
                    titulo: AppStrings.disciplinasEnHistorial,
                    valor: '${c.historial.length}',
                  ),
                  _Indicador(
                    icono: Icons.fact_check_outlined,
                    titulo: AppStrings.asistenciaGeneral,
                    valor: general.porcentaje == null
                        ? '—'
                        : '${general.porcentaje} %',
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space24),
              for (final inscripcion in c.historial) ...[
                _TarjetaHistorial(inscripcion: inscripcion, controller: c),
                const SizedBox(height: AppSizes.space12),
              ],
            ],
          );
        },
      ),
    );
  }
}

BoxDecoration _tarjeta() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSizes.radius),
    border: Border.all(color: AppColors.border),
  );
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.entrenadorCardAncho,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: _tarjeta(),
      child: Row(
        children: [
          Icon(icono, color: AppColors.primary),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: AppTextStyles.title),
                Text(
                  titulo,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({
    required this.inscripcion,
    required this.controller,
  });

  final Inscripcion inscripcion;
  final HistorialController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: _tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.space12,
            runSpacing: AppSizes.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(inscripcion.deporteNombre, style: AppTextStyles.subtitle),
              EstadoInscripcionChip(estado: inscripcion.estado),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          Text(
            '${AppStrings.inscritoEl} ${fechaCorta(inscripcion.fecha)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space12),
          _Asistencia(
            resumen: controller.resumenDe(inscripcion.id),
            consultando: controller.consultando(inscripcion.id),
          ),
        ],
      ),
    );
  }
}

class _Asistencia extends StatelessWidget {
  const _Asistencia({required this.resumen, required this.consultando});

  final ResumenAsistencia? resumen;
  final bool consultando;

  @override
  Widget build(BuildContext context) {
    final estilo = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    if (consultando) {
      return Text(AppStrings.calculandoAsistencia, style: estilo);
    }
    final r = resumen;
    if (r == null) return Text(AppStrings.asistenciaNoDisponible, style: estilo);
    if (r.total == 0) {
      return Text(AppStrings.sinClasesRegistradas, style: estilo);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.asistencia}: ${r.presentes} ${AppStrings.de} '
          '${r.total} ${AppStrings.clases} (${r.porcentaje} %)',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSizes.space8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          child: LinearProgressIndicator(
            value: r.presentes / r.total,
            minHeight: AppSizes.space8,
            backgroundColor: AppColors.border,
            color: (r.porcentaje ?? 0) >= 75
                ? AppColors.success
                : AppColors.primary,
          ),
        ),
      ],
    );
  }
}