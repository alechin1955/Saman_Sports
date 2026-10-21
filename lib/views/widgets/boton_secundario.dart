import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    super.key,
    required this.texto,
    required this.onPressed,
    this.anchoCompleto = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool anchoCompleto;

  @override
  Widget build(BuildContext context) {
    final boton = OutlinedButton(
      onPressed: onPressed,
      child: Text(
        texto,
        style: AppTextStyles.button.copyWith(color: AppColors.navy),
      ),
    );

    if (!anchoCompleto) {
      return boton;
    }
    return SizedBox(width: double.infinity, child: boton);
  }
}
