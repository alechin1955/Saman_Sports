import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class DisciplinasEntrenadorView extends StatefulWidget {
  const DisciplinasEntrenadorView({
    super.key,
    required this.auth,
    this.controller,
  });

  final AuthController auth;
  final EntrenadorController? controller;

  @override
  State<DisciplinasEntrenadorView> createState() =>
      _DisciplinasEntrenadorViewState();
}

class _DisciplinasEntrenadorViewState extends State<DisciplinasEntrenadorView> {
  late final EntrenadorController controller =
      widget.controller ?? EntrenadorController();
  late final bool _propio = widget.controller == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.cargar(cargarNominaInicial: false);
    });
  }

  @override
  void dispose() {
    if (_propio) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorDisciplinas,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Disciplinas',
      descripcion: 'Consulta tus equipos, horarios, cupos y canchas.',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null && controller.disciplinas.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MensajeError(texto: controller.error!),
                const SizedBox(height: AppSizes.space16),
                BotonSecundario(
                  texto: 'Reintentar',
                  onPressed: () =>
                      controller.cargar(cargarNominaInicial: false),
                ),
              ],
            );
          }
          if (controller.disciplinas.isEmpty) {
            return const EstadoVacio(
              icono: Icons.sports_outlined,
              titulo: 'No tienes disciplinas asignadas',
              texto: 'Cuando la coordinación te asigne una disciplina activa, aparecerá aquí.',
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth >= 760 ? 2 : 1;
              final ancho =
                  (constraints.maxWidth - AppSizes.space16 * (columnas - 1)) /
                  columnas;
              return Wrap(
                spacing: AppSizes.space16,
                runSpacing: AppSizes.space16,
                children: [
                  for (final disciplina in controller.disciplinas)
                    SizedBox(
                      width: ancho,
                      child: _DisciplinaCard(disciplina: disciplina),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DisciplinaCard extends StatelessWidget {
  const _DisciplinaCard({required this.disciplina});

  final Deporte disciplina;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.sports, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: Text(
                  disciplina.nombre,
                  style: AppTextStyles.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Chip(
                label: Text(disciplina.activo ? 'Activa' : 'Inactiva'),
                side: BorderSide.none,
                backgroundColor:
                    (disciplina.activo ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space24),
          _Dato(icono: Icons.schedule, texto: disciplina.horario),
          const SizedBox(height: AppSizes.space8),
          _Dato(
            icono: Icons.place_outlined,
            texto: disciplina.canchaNombre.isEmpty
                ? 'Cancha por confirmar'
                : disciplina.canchaNombre,
          ),
          const SizedBox(height: AppSizes.space8),
          _Dato(
            icono: Icons.groups_outlined,
            texto: '${disciplina.inscritos} inscritos de ${disciplina.cupos}',
          ),
          const SizedBox(height: AppSizes.space24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.entrenadorAsistencia,
                arguments: disciplina.id,
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Abrir registro de asistencia'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: AppSizes.iconSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.space8),
        Expanded(
          child: Text(
            texto.isEmpty ? 'Por confirmar' : texto,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}
