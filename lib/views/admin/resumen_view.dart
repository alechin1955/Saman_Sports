import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_resumen_controller.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/admin/widgets/tarjeta_resumen.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';

class ResumenView extends StatelessWidget {
  const ResumenView({
    super.key,
    required this.resumen,
    required this.deportes,
    required this.transacciones,
  });

  final AdminResumenController resumen;
  final AdminDeporteController deportes;
  final AdminTransaccionController transacciones;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([resumen, deportes, transacciones]),
      builder: (context, _) {
        if (resumen.cargando && resumen.conteos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (resumen.error != null && resumen.conteos.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resumen.error!, style: AppTextStyles.body),
              const SizedBox(height: AppSizes.space12),
              BotonPrimario(
                texto: AppStrings.reintentar,
                onPressed: () {
                  resumen.refrescar();
                },
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: BotonPrimario(
                texto: AppStrings.adminActualizar,
                cargando: resumen.cargando,
                onPressed: () {
                  resumen.refrescar();
                },
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            _Grilla(resumen: resumen),
            const SizedBox(height: AppSizes.space24),
            Text(AppStrings.adminOcupacion, style: AppTextStyles.title),
            const SizedBox(height: AppSizes.space12),
            _Ocupacion(deportes: deportes),
            const SizedBox(height: AppSizes.space24),
            Text(AppStrings.adminActividadReciente, style: AppTextStyles.title),
            const SizedBox(height: AppSizes.space12),
            _Actividad(transacciones: transacciones),
          ],
        );
      },
    );
  }
}

class _Grilla extends StatelessWidget {
  const _Grilla({required this.resumen});

  final AdminResumenController resumen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= AppSizes.desktop
            ? 4
            : constraints.maxWidth >= AppSizes.mobile
            ? 2
            : 1;
        final ancho =
            (constraints.maxWidth - AppSizes.space12 * (columnas - 1)) /
            columnas;
        final tarjetas = _tarjetas(resumen);
        return Wrap(
          spacing: AppSizes.space12,
          runSpacing: AppSizes.space12,
          children: [
            for (final tarjeta in tarjetas)
              SizedBox(width: ancho, child: tarjeta),
          ],
        );
      },
    );
  }

  List<TarjetaResumen> _tarjetas(AdminResumenController resumen) {
    String numero(String clave) => '${resumen.conteos[clave] ?? 0}';
    final ingresos = resumen.conteos['ingresos'] ?? 0;
    return [
      TarjetaResumen(
        icono: Icons.school_outlined,
        titulo: AppStrings.adminEstudiantes,
        valor: numero('estudiantes'),
      ),
      TarjetaResumen(
        icono: Icons.sports,
        titulo: AppStrings.adminEntrenadoresActivos,
        valor: numero('entrenadoresActivos'),
      ),
      TarjetaResumen(
        icono: Icons.sports_soccer_outlined,
        titulo: AppStrings.adminDeportesActivos,
        valor: numero('deportesActivos'),
      ),
      TarjetaResumen(
        icono: Icons.stadium_outlined,
        titulo: AppStrings.adminCanchas,
        valor: numero('canchasActivas'),
      ),
      TarjetaResumen(
        icono: Icons.how_to_reg_outlined,
        titulo: AppStrings.adminInscripcionesConfirmadas,
        valor: numero('inscripcionesConfirmadas'),
      ),
      TarjetaResumen(
        icono: Icons.pending_outlined,
        titulo: AppStrings.adminInscripcionesPendientes,
        valor: numero('inscripcionesPendientes'),
      ),
      TarjetaResumen(
        icono: Icons.payments_outlined,
        titulo: AppStrings.adminPagosPendientes,
        valor: numero('pagosPendientes'),
        color: AppColors.error,
      ),
      TarjetaResumen(
        icono: Icons.paid_outlined,
        titulo: AppStrings.adminPagosRealizados,
        valor: numero('pagosRealizados'),
        color: AppColors.success,
      ),
      TarjetaResumen(
        icono: Icons.attach_money,
        titulo: AppStrings.adminIngresos,
        valor: '\$${ingresos.toStringAsFixed(2)}',
      ),
      TarjetaResumen(
        icono: Icons.visibility_off_outlined,
        titulo: AppStrings.adminResenasOcultas,
        valor: numero('resenasOcultas'),
      ),
      TarjetaResumen(
        icono: Icons.support_agent_outlined,
        titulo: AppStrings.adminTicketsAbiertos,
        valor: numero('ticketsAbiertos'),
      ),
      TarjetaResumen(
        icono: Icons.event_outlined,
        titulo: AppStrings.adminEventosAprobados,
        valor: numero('eventosAprobados'),
      ),
    ];
  }
}

class _Ocupacion extends StatelessWidget {
  const _Ocupacion({required this.deportes});

  final AdminDeporteController deportes;

  @override
  Widget build(BuildContext context) {
    if (deportes.deportes.isEmpty) {
      return Text(AppStrings.adminSinDeportes, style: AppTextStyles.body);
    }
    return Column(
      children: [
        for (final deporte in deportes.deportes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space12),
            child: _BarraDeporte(deporte: deporte),
          ),
      ],
    );
  }
}

class _BarraDeporte extends StatelessWidget {
  const _BarraDeporte({required this.deporte});

  final Deporte deporte;

  @override
  Widget build(BuildContext context) {
    final total = deporte.cupos <= 0 ? 1 : deporte.cupos;
    final avance = (deporte.inscritos / total).clamp(0, 1).toDouble();
    final color = switch (deporte.estadoCupos) {
      EstadoCupos.completo => AppColors.error,
      EstadoCupos.pocosCupos => AppColors.primary,
      EstadoCupos.disponible => AppColors.success,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deporte.nombre, style: AppTextStyles.label),
            const SizedBox(height: AppSizes.space8),
            LinearProgressIndicator(
              value: avance,
              color: color,
              backgroundColor: AppColors.border,
              minHeight: AppSizes.space8,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            const SizedBox(height: AppSizes.space4),
            Text(
              '${deporte.inscritos}/${deporte.cupos}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Actividad extends StatelessWidget {
  const _Actividad({required this.transacciones});

  final AdminTransaccionController transacciones;

  @override
  Widget build(BuildContext context) {
    final recientes = transacciones.transacciones.take(5).toList();
    if (recientes.isEmpty) {
      return Text(AppStrings.adminSinActividad, style: AppTextStyles.body);
    }
    return Column(
      children: [
        for (final item in recientes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.descripcion, style: AppTextStyles.body),
            subtitle: Text(
              '${item.modulo} · ${item.rol}',
              style: AppTextStyles.bodySmall,
            ),
          ),
      ],
    );
  }
}
