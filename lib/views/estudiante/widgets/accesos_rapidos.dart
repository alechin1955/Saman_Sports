import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

/// Tarjetas del Dashboard que llevan a las secciones principales.
/// 1 columna en móvil, 2 en tablet y 4 en escritorio.
class AccesosRapidos extends StatelessWidget {
  const AccesosRapidos({super.key});

  static const List<_Acceso> _accesos = [
    _Acceso(
      icono: Icons.search,
      titulo: AppStrings.explorarDeportes,
      texto: AppStrings.accesoExplorarTexto,
      ruta: AppRoutes.estudianteExplorar,
    ),
    _Acceso(
      icono: Icons.event_note_outlined,
      titulo: AppStrings.misDisciplinas,
      texto: AppStrings.accesoDisciplinasTexto,
      ruta: AppRoutes.estudianteDisciplinas,
    ),
    _Acceso(
      icono: Icons.forum_outlined,
      titulo: AppStrings.comunidad,
      texto: AppStrings.accesoComunidadTexto,
      ruta: AppRoutes.estudianteComunidad,
    ),
    _Acceso(
      icono: Icons.person_outline,
      titulo: AppStrings.miPerfil,
      texto: AppStrings.accesoPerfilTexto,
      ruta: AppRoutes.estudiantePerfil,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho < AppSizes.mobile
            ? 1
            : ancho < AppSizes.desktop
            ? 2
            : 4;
        const espacio = AppSizes.space16;
        final anchoTarjeta = ((ancho - espacio * (columnas - 1)) / columnas)
            .floorToDouble();

        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final acceso in _accesos)
              SizedBox(
                width: anchoTarjeta,
                child: _TarjetaAcceso(acceso: acceso),
              ),
          ],
        );
      },
    );
  }
}

class _Acceso {
  const _Acceso({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.ruta,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final String ruta;
}

class _TarjetaAcceso extends StatelessWidget {
  const _TarjetaAcceso({required this.acceso});

  final _Acceso acceso;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        onTap: () => Navigator.pushReplacementNamed(context, acceso.ruta),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(acceso.icono, color: AppColors.primary),
              ),
              const SizedBox(height: AppSizes.space12),
              Text(
                acceso.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSizes.space4),
              Text(
                acceso.texto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
