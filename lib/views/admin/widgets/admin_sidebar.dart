import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';

enum SeccionAdmin {
  resumen(
    AppStrings.adminResumen,
    AppStrings.adminResumenDescripcion,
    Icons.dashboard_outlined,
  ),
  deportes(
    AppStrings.deportes,
    AppStrings.adminDeportesDescripcion,
    Icons.sports_soccer_outlined,
  ),
  entrenadores(
    AppStrings.entrenadores,
    AppStrings.adminEntrenadoresDescripcion,
    Icons.sports,
  ),
  estudiantes(
    AppStrings.adminEstudiantes,
    AppStrings.adminEstudiantesDescripcion,
    Icons.school_outlined,
  ),
  inscripciones(
    AppStrings.adminInscripciones,
    AppStrings.adminInscripcionesDescripcion,
    Icons.how_to_reg_outlined,
  ),
  pagos(
    AppStrings.pagos,
    AppStrings.adminPagosDescripcion,
    Icons.payments_outlined,
  ),
  eventos(
    AppStrings.adminEventos,
    AppStrings.adminEventosDescripcion,
    Icons.event_outlined,
  ),
  resenas(
    AppStrings.resenas,
    AppStrings.adminResenasDescripcion,
    Icons.star_outline,
  ),
  transacciones(
    AppStrings.adminTransacciones,
    AppStrings.adminTransaccionesDescripcion,
    Icons.receipt_long_outlined,
  ),
  soporte(
    AppStrings.soporte,
    AppStrings.adminSoporteMenuDescripcion,
    Icons.support_agent_outlined,
  );

  const SeccionAdmin(this.titulo, this.descripcion, this.icono);

  final String titulo;
  final String descripcion;
  final IconData icono;
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.activa,
    required this.onSeleccion,
    required this.auth,
    this.enDrawer = false,
  });

  final SeccionAdmin activa;
  final ValueChanged<SeccionAdmin> onSeleccion;
  final AuthController auth;
  final bool enDrawer;

  static const List<SeccionAdmin> _principales = [
    SeccionAdmin.resumen,
    SeccionAdmin.deportes,
    SeccionAdmin.entrenadores,
    SeccionAdmin.estudiantes,
    SeccionAdmin.inscripciones,
    SeccionAdmin.pagos,
    SeccionAdmin.eventos,
    SeccionAdmin.resenas,
    SeccionAdmin.transacciones,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.panelMenuAncho,
      child: Material(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSizes.space16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppLogo(size: AppSizes.logoHeader, mostrarTexto: true),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.space12),
                children: [
                  for (final seccion in _principales)
                    _ItemSeccion(
                      seccion: seccion,
                      activa: seccion == activa,
                      enDrawer: enDrawer,
                      onSeleccion: onSeleccion,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space12,
                AppSizes.space8,
                AppSizes.space12,
                0,
              ),
              child: _ItemSeccion(
                seccion: SeccionAdmin.soporte,
                activa: activa == SeccionAdmin.soporte,
                enDrawer: enDrawer,
                onSeleccion: onSeleccion,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
              child: Text(
                AppStrings.panelAdmin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.space12),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                hoverColor: AppColors.error.withValues(alpha: 0.06),
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  AppStrings.cerrarSesion,
                  style: AppTextStyles.label.copyWith(color: AppColors.error),
                ),
                onTap: () async {
                  await auth.cerrarSesion();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (_) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemSeccion extends StatelessWidget {
  const _ItemSeccion({
    required this.seccion,
    required this.activa,
    required this.enDrawer,
    required this.onSeleccion,
  });

  final SeccionAdmin seccion;
  final bool activa;
  final bool enDrawer;
  final ValueChanged<SeccionAdmin> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space4),
      child: ListTile(
        dense: true,
        selected: activa,
        selectedTileColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        leading: Icon(
          seccion.icono,
          color: activa ? AppColors.surface : AppColors.textSecondary,
        ),
        title: Text(
          seccion.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: activa ? AppColors.surface : AppColors.navy,
          ),
        ),
        onTap: () {
          if (enDrawer) Navigator.pop(context);
          onSeleccion(seccion);
        },
      ),
    );
  }
}
