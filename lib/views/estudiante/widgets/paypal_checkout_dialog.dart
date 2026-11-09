import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/pagos_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/formato_monto.dart';

/// Abre la ventana de pago con PayPal (simulado, RF-15).
Future<void> mostrarCheckoutPaypal(
  BuildContext context,
  PagosController pagos,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CheckoutPaypal(pagos: pagos),
  );
}

enum _Fase { resumen, procesando, listo, error }

/// Simula el recorrido de PayPal en tres momentos: resumen del cobro,
/// conexión con PayPal y comprobante con el ID de transacción.
class _CheckoutPaypal extends StatefulWidget {
  const _CheckoutPaypal({required this.pagos});

  final PagosController pagos;

  @override
  State<_CheckoutPaypal> createState() => _CheckoutPaypalState();
}

class _CheckoutPaypalState extends State<_CheckoutPaypal> {
  _Fase _fase = _Fase.resumen;
  String _orden = '';
  String _error = '';

  Future<void> _pagar() async {
    setState(() => _fase = _Fase.procesando);
    try {
      final orden = await widget.pagos.pagarConPaypal();
      if (!mounted) return;
      setState(() {
        _orden = orden;
        _fase = _Fase.listo;
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _fase = _Fase.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.errorInesperado;
        _fase = _Fase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.pagos.configuracion;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.navy,
          ),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Text(
              AppStrings.pagoPayPalTitulo,
              style: AppTextStyles.title,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: SingleChildScrollView(
          child: switch (_fase) {
            _Fase.resumen => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Dato(
                  etiqueta: AppStrings.conceptoPago,
                  valor:
                      '${AppStrings.cuotaDeportiva} ${config?.periodo ?? ''}',
                ),
                _Dato(
                  etiqueta: AppStrings.montoAPagar,
                  valor: montoUsd(config?.monto ?? 0),
                ),
                const SizedBox(height: AppSizes.space8),
                Text(
                  AppStrings.pagoSimuladoNota,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            _Fase.procesando => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppSizes.space16),
                CircularProgressIndicator(),
                SizedBox(height: AppSizes.space16),
                Text(AppStrings.conectandoPaypal),
              ],
            ),
            _Fase.listo => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: AppSizes.iconLarge,
                ),
                const SizedBox(height: AppSizes.space12),
                Text(AppStrings.pagoEnviado, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSizes.space12),
                _Dato(etiqueta: AppStrings.idTransaccion, valor: _orden),
                Text(AppStrings.pagoEnviadoTexto, style: AppTextStyles.body),
              ],
            ),
            _Fase.error => Text(
              _error,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          },
        ),
      ),
      actions: switch (_fase) {
        _Fase.resumen => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            onPressed: _pagar,
            child: const Text(AppStrings.pagarConPaypal),
          ),
        ],
        _Fase.procesando => const [],
        _Fase.listo => [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.listo),
          ),
        ],
        _Fase.error => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cerrar),
          ),
        ],
      },
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(valor, style: AppTextStyles.label),
        ],
      ),
    );
  }
}
