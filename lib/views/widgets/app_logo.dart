import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.mostrarTexto = false});

  final double size;
  final bool mostrarTexto;

  static const String asset = 'assets/images/logo_saman_sports.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
        if (mostrarTexto) ...[
          const SizedBox(width: AppSizes.space8),
          Text(AppStrings.appName, style: AppTextStyles.subtitle),
        ],
      ],
    );
  }
}
