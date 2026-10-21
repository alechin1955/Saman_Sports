import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';

class PublicHeader extends StatelessWidget implements PreferredSizeWidget {
  const PublicHeader({
    super.key,
    required this.linkActivo,
    this.onIniciarSesion,
    this.onRegistrarse,
    this.onLink,
  });

  final String linkActivo;
  final VoidCallback? onIniciarSesion;
  final VoidCallback? onRegistrarse;
  final void Function(String link)? onLink;

  static const List<String> links = [
    AppStrings.inicio,
    AppStrings.deportes,
    AppStrings.entrenadores,
    AppStrings.resenas,
  ];

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.headerHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esEscritorio = constraints.maxWidth >= AppSizes.desktop;
        return Material(
          color: AppColors.surface,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
              child: Row(
                children: [
                  const AppLogo(size: AppSizes.logoHeader, mostrarTexto: true),
                  if (esEscritorio) ...[
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final link in links)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.space8,
                                ),
                                child: _NavLink(
                                  texto: link,
                                  activo: link == linkActivo,
                                  onPressed: () => onLink?.call(link),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    BotonPrimario(
                      texto: AppStrings.iniciarSesion,
                      onPressed: onIniciarSesion,
                    ),
                    const SizedBox(width: AppSizes.space8),
                    BotonPrimario(
                      texto: AppStrings.registrarse,
                      onPressed: onRegistrarse,
                    ),
                  ] else
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, color: AppColors.navy),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppLogo(size: 40, mostrarTexto: true),
              ),
              const SizedBox(height: AppSizes.space32),
              for (final link in links)
                _NavLink(
                  texto: link,
                  activo: link == linkActivo,
                  onPressed: () {
                    Navigator.pop(context);
                    onLink?.call(link);
                  },
                ),
              const Spacer(),
              BotonPrimario(
                texto: AppStrings.iniciarSesion,
                onPressed: onIniciarSesion,
                anchoCompleto: true,
              ),
              const SizedBox(height: AppSizes.space12),
              BotonPrimario(
                texto: AppStrings.registrarse,
                onPressed: onRegistrarse,
                anchoCompleto: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.texto, required this.activo, this.onPressed});

  final String texto;
  final bool activo;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.primary : AppColors.navy;
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.space12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(texto, style: AppTextStyles.label.copyWith(color: color)),
            const SizedBox(height: AppSizes.space4),
            Container(
              height: 2,
              width: AppSizes.space24,
              color: activo ? AppColors.primary : AppColors.surface,
            ),
          ],
        ),
      ),
    );
  }
}
