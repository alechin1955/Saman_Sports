import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';

class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _PistaPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _PistaPainter extends CustomPainter {
  const _PistaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final edificio = Paint()..color = AppColors.border.withValues(alpha: 0.9);
    final bloque = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.08, size.width * 0.5, size.height * 0.42),
      const Radius.circular(12),
    );
    canvas.drawRRect(bloque, edificio);

    final ventana = Paint()..color = AppColors.surface.withValues(alpha: 0.8);
    for (var fila = 0; fila < 3; fila++) {
      for (var columna = 0; columna < 4; columna++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.42 + columna * size.width * 0.09,
              size.height * 0.14 + fila * size.height * 0.1,
              size.width * 0.06,
              size.height * 0.06,
            ),
            const Radius.circular(4),
          ),
          ventana,
        );
      }
    }

    final pista = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final camino = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width,
        size.height * 0.78,
      );
    canvas.drawPath(camino, pista);
    canvas.drawPath(
      camino.shift(const Offset(0, 28)),
      pista..color = AppColors.primary.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
