import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';
import 'package:saman_sports/views/widgets/auth_info_panel.dart';

class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    super.key,
    required this.panelIzquierdo,
    required this.formulario,
  });

  final AuthInfoPanel panelIzquierdo;
  final Widget formulario;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esEscritorio = constraints.maxWidth >= AppSizes.desktop;
        if (!esEscritorio) {
          return ColoredBox(
            color: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppLogo(size: 40, mostrarTexto: true),
                  ),
                  const SizedBox(height: AppSizes.space32),
                  formulario,
                ],
              ),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 45,
              child: ColoredBox(
                color: AppColors.background,
                child: SingleChildScrollView(child: panelIzquierdo),
              ),
            ),
            Expanded(
              flex: 55,
              child: ColoredBox(
                color: AppColors.surface,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.space32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.formMaxWidth,
                      ),
                      child: formulario,
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
