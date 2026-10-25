import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';

/// Estado vacío de las pantallas del estudiante: ícono, título, texto
/// y una acción opcional (por ejemplo, "Explorar deportes").
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.textoAccion,
    this.onAccion,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final String? textoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final accion = textoAccion;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: AppSizes.iconLarge,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(
              icono,
              color: AppColors.primary,
              size: AppSizes.iconMedium,
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          Text(
            titulo,
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.space8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (accion != null && onAccion != null) ...[
            const SizedBox(height: AppSizes.space24),
            BotonSecundario(texto: accion, onPressed: onAccion),
          ],
        ],
      ),
    );
  }
}
