import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador/entrenador_notificacion_controller.dart';
import 'package:saman_sports/controllers/inicio_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/views/entrenador/notificaciones_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

class DashboardEntrenadorView extends StatefulWidget {
  const DashboardEntrenadorView({
    super.key,
    required this.auth,
    this.controller,
    this.notificaciones,
  });

  final AuthController auth;
  final InicioEntrenadorController? controller;
  final EntrenadorNotificacionController? notificaciones;

  @override
  State<DashboardEntrenadorView> createState() =>
      _DashboardEntrenadorViewState();
}

class _DashboardEntrenadorViewState extends State<DashboardEntrenadorView> {
  late final InicioEntrenadorController controller =
      widget.controller ?? InicioEntrenadorController();
  late final EntrenadorNotificacionController notificaciones =
      widget.notificaciones ?? EntrenadorNotificacionController();
  late final bool _propio = widget.controller == null;
  late final bool _avisosPropios = widget.notificaciones == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.cargar();
      notificaciones.iniciar();
    });
  }

  @override
  void dispose() {
    if (_propio) controller.dispose();
    if (_avisosPropios) notificaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.dashboardEntrenador,
      subtituloPanel: AppStrings.entPanel,
      titulo: AppStrings.inicio,
      descripcion: AppStrings.entInicioDescripcion,
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
                  texto: AppStrings.reintentar,
                  onPressed: controller.cargar,
                ),
              ],
            );
          }
          final perfil = controller.perfil;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CampanaEntrenador(controller: notificaciones),
              ),
              _BienvenidaEntrenador(
                nombre: perfil?.nombre ?? AppStrings.entNombreFallback,
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
                          etiqueta: AppStrings.entDisciplinasAsignadas,
                        ),
                      ),
                      SizedBox(
                        width: ancho,
                        child: _ResumenCard(
                          icono: Icons.groups_outlined,
                          valor: '${controller.totalEstudiantes}',
                          etiqueta: AppStrings.entEstudiantesInscritosEtiqueta,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSizes.space24),
              _ProximaClase(controller: controller),
              const SizedBox(height: AppSizes.space32),
              Text(AppStrings.entAccesosRapidos, style: AppTextStyles.title),
              const SizedBox(height: AppSizes.space16),
              const _AccesosEntrenador(),
              const SizedBox(height: AppSizes.space32),
              Text(AppStrings.entAsistenciaReciente, style: AppTextStyles.title),
              const SizedBox(height: AppSizes.space16),
              if (controller.advertenciaAsistencias != null) ...[
                MensajeError(texto: controller.advertenciaAsistencias!),
                const SizedBox(height: AppSizes.space12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: BotonSecundario(
                    texto: AppStrings.reintentar,
                    onPressed: controller.cargar,
                  ),
                ),
                const SizedBox(height: AppSizes.space16),
              ],
              if (controller.asistenciasRecientes.isEmpty &&
                  controller.advertenciaAsistencias == null)
                const EstadoVacio(
                  icono: Icons.fact_check_outlined,
                  titulo: AppStrings.entSinAsistencias,
                  texto: AppStrings.entSinAsistenciasTexto,
                )
              else if (controller.asistenciasRecientes.isNotEmpty)
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
                Text(AppStrings.entHola(nombre), style: AppTextStyles.title),
                const SizedBox(height: AppSizes.space4),
                Text(
                  disciplina.isEmpty
                      ? AppStrings.entGestionaEquipos
                      : AppStrings.entEntrenadorDe(disciplina),
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
    final disciplina = clase?.disciplina;
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
                Text(AppStrings.entProximaClase, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSizes.space8),
                Text(
                  disciplina == null
                      ? AppStrings.entSinClase
                      : '${disciplina.nombre} · ${_horario(clase!)}',
                  style: AppTextStyles.body,
                ),
                if (disciplina != null && disciplina.canchaNombre.isNotEmpty)
                  Text(
                    disciplina.canchaNombre,
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

  String _horario(ProximaClaseEntrenador clase) {
    final inicio = clase.inicio;
    final franja = clase.franja;
    if (inicio == null || franja == null) return clase.disciplina.horario;
    const dias = AppStrings.entDiasSemana;
    return '${dias[inicio.weekday - 1]} ${minutosATexto(franja.horaInicio)}–${minutosATexto(franja.horaFin)}';
  }
}

class _AccesosEntrenador extends StatelessWidget {
  const _AccesosEntrenador();

  static const accesos = [
    (Icons.sports_outlined, AppStrings.disciplinas, AppRoutes.entrenadorDisciplinas),
    (Icons.fact_check_outlined, AppStrings.entPasarLista, AppRoutes.entrenadorAsistencia),
    (Icons.event_outlined, AppStrings.entSolicitarEvento, AppRoutes.entrenadorEventos),
    (Icons.person_outline, AppStrings.miPerfil, AppRoutes.entrenadorPerfil),
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
            AppStrings.entPresentesAusentes(
              registro.presentes,
              registro.ausentes,
            ),
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
