import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/home/widgets/hero_illustration.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onExplorar,
    required this.onRegistrarme,
    this.disciplinas = 0,
    this.entrenadores = 0,
    this.valoracion = '0.0',
    this.resenas = 0,
  });

  final VoidCallback onExplorar;
  final VoidCallback onRegistrarme;
  final int disciplinas;
  final int entrenadores;
  final String valoracion;
  final int resenas;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esMovil = constraints.maxWidth < AppSizes.mobile;
        final esEscritorio = constraints.maxWidth >= AppSizes.desktop;
        final texto = _HeroTexto(
          fontSize: esMovil ? AppSizes.heroTitleMobile : AppSizes.heroTitleDesktop,
          onExplorar: onExplorar,
          onRegistrarme: onRegistrarme,
          disciplinas: disciplinas,
          entrenadores: entrenadores,
          valoracion: valoracion,
          resenas: resenas,
        );

        if (!esEscritorio) {
          return Padding(
            padding: const EdgeInsets.all(AppSizes.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                texto,
                if (!esMovil) ...[
                  const SizedBox(height: AppSizes.space32),
                  const SizedBox(
                    height: AppSizes.heroIllustrationMobile,
                    child: HeroIllustration(),
                  ),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space48,
            vertical: AppSizes.space32,
          ),
          child: Row(
            children: [
              Expanded(flex: 6, child: texto),
              const SizedBox(width: AppSizes.space32),
              const Expanded(
                flex: 5,
                child: SizedBox(
                  height: AppSizes.heroIllustrationDesktop,
                  child: HeroIllustration(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroTexto extends StatelessWidget {
  const _HeroTexto({
    required this.fontSize,
    required this.onExplorar,
    required this.onRegistrarme,
    required this.disciplinas,
    required this.entrenadores,
    required this.valoracion,
    required this.resenas,
  });

  final double fontSize;
  final VoidCallback onExplorar;
  final VoidCallback onRegistrarme;
  final int disciplinas;
  final int entrenadores;
  final String valoracion;
  final int resenas;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.titleLarge.copyWith(
      fontSize: fontSize,
      height: 1.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PillUnimet(),
        const SizedBox(height: AppSizes.space32),
        _linea(AppStrings.homeTitulo, base),
        _linea(AppStrings.homeTituloDestacado, base.copyWith(color: AppColors.primary)),
        _linea(AppStrings.homeTituloFinal, base),
        const SizedBox(height: AppSizes.space24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.heroTextMaxWidth),
          child: Text(
            AppStrings.homeDescripcion,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSizes.space32),
        Wrap(
          spacing: AppSizes.space12,
          runSpacing: AppSizes.space12,
          children: [
            BotonPrimario(
              texto: AppStrings.explorarDeportes,
              icono: Icons.arrow_forward,
              onPressed: onExplorar,
            ),
            BotonSecundario(
              texto: AppStrings.registrarme,
              onPressed: onRegistrarme,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space24),
        Wrap(
          spacing: AppSizes.space16,
          runSpacing: AppSizes.space8,
          children: [
            Text('$disciplinas+ ${AppStrings.disciplinas}', style: AppTextStyles.label),
            Text('$entrenadores ${AppStrings.entrenadores}', style: AppTextStyles.label),
            Text('$valoracion★ ${AppStrings.valoracion}', style: AppTextStyles.label),
            Text('$resenas ${AppStrings.resenas}', style: AppTextStyles.label),
          ],
        ),
      ],
    );
  }

  Widget _linea(String texto, TextStyle estilo) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(texto, style: estilo),
    );
  }
}

class _PillUnimet extends StatelessWidget {
  const _PillUnimet();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space16,
            vertical: AppSizes.space8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.space32),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.space8,
                height: AppSizes.space8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.space8),
              Text(
                AppStrings.homeBadge,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
