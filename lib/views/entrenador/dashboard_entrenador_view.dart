import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/views/entrenador/widgets/disciplinas_nomina.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Punto de entrada del entrenador, con la estructura compartida por los roles.
class DashboardEntrenadorView extends StatefulWidget {
  const DashboardEntrenadorView({
    super.key,
    required this.auth,
    this.controller,
    this.asistencia,
  });

  final AuthController auth;
  final EntrenadorController? controller;
  final AsistenciaController? asistencia;

  @override
  State<DashboardEntrenadorView> createState() =>
      _DashboardEntrenadorViewState();
}

class _DashboardEntrenadorViewState extends State<DashboardEntrenadorView> {
  late final EntrenadorController controller =
      widget.controller ?? EntrenadorController();

  late final AsistenciaController asistencia =
      widget.asistencia ?? AsistenciaController();
  String? _seleccionCargada;
  Object? _nominaCargada;

  void _sincronizarAsistencia() {
    if (!mounted ||
        controller.cargando ||
        controller.cargandoNomina ||
        controller.error != null) {
      return;
    }
    final id = controller.seleccionId;
    if (id != null &&
        (id != _seleccionCargada ||
            !identical(_nominaCargada, controller.alumnos)) &&
        !asistencia.cambios &&
        !asistencia.guardando) {
      _seleccionCargada = id;
      _nominaCargada = controller.alumnos;
      asistencia.abrir(id, asistencia.fecha, controller.alumnos);
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_sincronizarAsistencia);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.cargar();
    });
  }

  @override
  void dispose() {
    controller.removeListener(_sincronizarAsistencia);
    if (widget.controller == null) controller.dispose();
    if (widget.asistencia == null) asistencia.dispose();
    super.dispose();
  }

  Future<bool> _permitirSalida() async {
    if (asistencia.guardando) return false;
    if (!asistencia.cambios) return true;
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tienes asistencia sin guardar'),
        content: const Text(
          'Puedes continuar editando o salir y descartar los cambios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );
    if (salir == true) asistencia.descartarBorrador();
    return salir == true;
  }

  static const opciones = [
    OpcionPanel(
      icono: Icons.dashboard_outlined,
      texto: 'Dashboard',
      ruta: AppRoutes.dashboardEntrenador,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: asistencia,
      builder: (context, _) => PopScope(
        canPop: !asistencia.cambios && !asistencia.guardando,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await _permitirSalida()) {
            await WidgetsBinding.instance.endOfFrame;
            if (context.mounted) {
              Navigator.maybePop(context);
            }
          }
        },
        child: PanelLayout(
          permitirSalida: _permitirSalida,
          auth: widget.auth,
          opciones: opciones,
          rutaActiva: AppRoutes.dashboardEntrenador,
          subtituloPanel: 'Panel del entrenador',
          titulo: 'Dashboard del entrenador',
          descripcion: 'Organiza tus disciplinas y acompaña a tu equipo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.space24),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sports_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    const SizedBox(height: AppSizes.space16),
                    Text(
                      'Bienvenido a tu espacio deportivo',
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.space8),
                    Text(
                      'Consulta tus disciplinas, revisa los inscritos y lleva el control de cada entrenamiento.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space24),
              DisciplinasNomina(controller: controller, asistencia: asistencia),
            ],
          ),
        ),
      ),
    );
  }
}
