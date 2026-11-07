import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/inicio_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class DashboardEntrenadorView extends StatefulWidget {
  const DashboardEntrenadorView({
    super.key,
    required this.auth,
    this.controller,
  });

  final AuthController auth;
  final InicioEntrenadorController? controller;

  @override
  State<DashboardEntrenadorView> createState() =>
      _DashboardEntrenadorViewState();
}

class _DashboardEntrenadorViewState extends State<DashboardEntrenadorView> {
  late final InicioEntrenadorController controller =
      widget.controller ?? InicioEntrenadorController();
  late final bool _propio = widget.controller == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.cargar();
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
      rutaActiva: AppRoutes.dashboardEntrenador,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Inicio',
      descripcion: 'Tu resumen deportivo y los próximos pasos de tu equipo.',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.perfil == null && controller.error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null && controller.perfil == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MensajeError(texto: controller.error!),
                const SizedBox(height: AppSizes.space16),
                BotonSecundario(
                  texto: 'Reintentar',
                  onPressed: controller.cargar,
                ),
              ],
            );
          }
          final perfil = controller.perfil;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BienvenidaEntrenador(
                nombre: perfil?.nombre ?? 'Entrenador',
                disciplina: perfil?.disciplina ?? '',
                iniciales: perfil?.iniciales ?? 'E',
              ),
              const SizedBox(height: AppSizes.space24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final ancho = constraints.maxWidth < 620
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSizes.space16) / 2;
                  return Wrap(
                    spacing: AppSizes.space16,
                    runSpacing: AppSizes.space16,
                    children: [
                      SizedBox(
                        width: ancho,
                        child: _ResumenCard(
                          icono: Icons.sports_outlined,
                          valor: '${controller.disciplinas.length}',
                          etiqueta: 'Disciplinas asignadas',
                        ),
                      ),
                      SizedBox(
                        width: ancho,
                        child: _ResumenCard(
                          icono: Icons.groups_outlined,
                          valor: '${controller.totalEstudiantes}',
                          etiqueta: 'Estudiantes inscritos',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSizes.space24),
              _ProximaClase(controller: controller),
              const SizedBox(height: AppSizes.space32),
              Text('Accesos rápidos', style: AppTextStyles.title),
              const SizedBox(height: AppSizes.space16),
              const _AccesosEntrenador(),
              const SizedBox(height: AppSizes.space32),
              Text('Asistencia reciente', style: AppTextStyles.title),
              const SizedBox(height: AppSizes.space16),
              if (controller.asistenciasRecientes.isEmpty)
                const EstadoVacio(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Aún no hay asistencias registradas',
                  texto: 'Cuando pases lista, las sesiones más recientes aparecerán aquí.',
                )
              else
                for (final registro in controller.asistenciasRecientes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.space12),
                    child: _AsistenciaCard(registro: registro),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _BienvenidaEntrenador extends StatelessWidget {
  const _BienvenidaEntrenador({
    required this.nombre,
    required this.disciplina,
    required this.iniciales,
  });

  final String nombre;
  final String disciplina;
  final String iniciales;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizes.iconMedium,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              iniciales,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSizes.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $nombre', style: AppTextStyles.title),
                const SizedBox(height: AppSizes.space4),
                Text(
                  disciplina.isEmpty
                      ? 'Gestiona tus equipos desde un solo lugar.'
                      : 'Entrenador de $disciplina',
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

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(icono, color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: AppTextStyles.titleLarge),
                Text(
                  etiqueta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

class _ProximaClase extends StatelessWidget {
  const _ProximaClase({required this.controller});

  final InicioEntrenadorController controller;

  @override
  Widget build(BuildContext context) {
    final clase = controller.proximaClase;
    return _Tarjeta(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_outlined, color: AppColors.primary),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próxima clase', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSizes.space8),
                Text(
                  clase == null
                      ? 'No tienes una clase programada.'
                      : '${clase.nombre} · ${clase.horario}',
                  style: AppTextStyles.body,
                ),
                if (clase != null && clase.canchaNombre.isNotEmpty)
                  Text(
                    clase.canchaNombre,
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

class _AccesosEntrenador extends StatelessWidget {
  const _AccesosEntrenador();

  static const accesos = [
    (Icons.sports_outlined, 'Disciplinas', AppRoutes.entrenadorDisciplinas),
    (Icons.fact_check_outlined, 'Pasar lista', AppRoutes.entrenadorAsistencia),
    (Icons.event_outlined, 'Solicitar evento', AppRoutes.entrenadorEventos),
    (Icons.person_outline, 'Mi perfil', AppRoutes.entrenadorPerfil),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth < AppSizes.mobile
            ? 1
            : constraints.maxWidth < AppSizes.desktop
            ? 2
            : 4;
        final ancho =
            (constraints.maxWidth - AppSizes.space16 * (columnas - 1)) /
            columnas;
        return Wrap(
          spacing: AppSizes.space16,
          runSpacing: AppSizes.space16,
          children: [
            for (final acceso in accesos)
              SizedBox(
                width: ancho,
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, acceso.$3),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(acceso.$1, color: AppColors.primary),
                          const SizedBox(height: AppSizes.space12),
                          Text(acceso.$2, style: AppTextStyles.subtitle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AsistenciaCard extends StatelessWidget {
  const _AsistenciaCard({required this.registro});

  final AsistenciaRecienteEntrenador registro;

  @override
  Widget build(BuildContext context) {
    final fecha = registro.sesion.fecha;
    return _Tarjeta(
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(registro.disciplina.nombre, style: AppTextStyles.subtitle),
                Text(
                  '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${registro.presentes} presentes · ${registro.ausentes} ausentes',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
