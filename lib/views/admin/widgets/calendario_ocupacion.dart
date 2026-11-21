import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_calendario_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/bloque_ocupado.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/views/admin/widgets/tabla_desplazable.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class CalendarioOcupacion extends StatelessWidget {
  const CalendarioOcupacion({super.key, required this.controller});

  final AdminCalendarioController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.error != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MensajeError(texto: controller.error!),
              const SizedBox(height: AppSizes.space12),
              BotonSecundario(
                texto: AppStrings.reintentar,
                onPressed: controller.reintentar,
              ),
            ],
          );
        }
        if (controller.cargando && controller.canchasActivas.isEmpty) {
          return const Center(
            child: SizedBox(
              key: Key('calendario-cargando'),
              width: AppSizes.space24,
              height: AppSizes.space24,
            ),
          );
        }
        if (controller.canchasActivas.isEmpty) {
          return Text(AppStrings.adminCalendarioSinCanchas);
        }
        return SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Barra(controller: controller),
            const SizedBox(height: AppSizes.space16),
            LayoutBuilder(
              builder: (context, constraints) {
                final pantalla = MediaQuery.sizeOf(context).width;
                final ancho = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : pantalla;
                if (pantalla < AppSizes.desktop) {
                  return _ListaDias(controller: controller);
                }
                final anchoMin = 64 + 7 * AppSizes.calendarioAnchoColumnaMin;
                final grilla = _GrillaSemana(controller: controller);
                if (ancho < anchoMin) {
                  return TablaDesplazable(
                    child: SizedBox(width: anchoMin, child: grilla),
                  );
                }
                return grilla;
              },
            ),
          ],
          ),
        );
      },
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.controller});

  final AdminCalendarioController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.space12,
      runSpacing: AppSizes.space8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<String>(
          value: controller.canchaId ?? '',
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(AppStrings.adminCalendarioTodas),
            ),
            for (final cancha in controller.canchasActivas)
              DropdownMenuItem(value: cancha.id, child: Text(cancha.nombre)),
          ],
          onChanged: (id) =>
              controller.seleccionarCancha(id == null || id.isEmpty ? null : id),
        ),
        IconButton(
          tooltip: AppStrings.adminCalendarioHoy,
          onPressed: controller.semanaAnterior,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: controller.semanaSiguiente,
          icon: const Icon(Icons.chevron_right),
        ),
        TextButton(
          onPressed: controller.irAHoy,
          child: Text(AppStrings.adminCalendarioHoy),
        ),
        Text(controller.rangoSemana, style: AppTextStyles.label),
        _Leyenda(
          color: AppColors.navy,
          texto: AppStrings.adminCalendarioDeporte,
        ),
        _Leyenda(
          color: AppColors.primary,
          texto: AppStrings.adminCalendarioEvento,
        ),
        _Leyenda(
          color: AppColors.success.withValues(alpha: 0.25),
          texto: AppStrings.adminCalendarioLibre,
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: AppSizes.space4),
        Text(texto, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _ListaDias extends StatelessWidget {
  const _ListaDias({required this.controller});

  final AdminCalendarioController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var dia = 1; dia <= 7; dia++) ...[
          Text(
            '${_nombreDia(dia)} ${controller.diasSemana[dia - 1].day}',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppSizes.space8),
          ..._lineas(dia),
          const SizedBox(height: AppSizes.space16),
        ],
      ],
    );
  }

  List<Widget> _lineas(int dia) {
    final bloques = controller.bloquesDe(dia);
    final libres = controller.huecosLibres(dia);
    if (bloques.isEmpty && libres.isEmpty) {
      return [Text(AppStrings.adminCalendarioDiaLibre)];
    }
    return [
      for (final bloque in bloques)
        Text(
          '${minutosATexto(bloque.inicio)}–${minutosATexto(bloque.fin)} · ${bloque.titulo} · ${_tipo(bloque.tipo)}',
        ),
      if (controller.canchaId != null)
        for (final libre in libres)
          Text(
            '${AppStrings.adminCalendarioLibre}: ${minutosATexto(libre.inicio)}–${minutosATexto(libre.fin)}',
          ),
    ];
  }
}

class _GrillaSemana extends StatelessWidget {
  const _GrillaSemana({required this.controller});

  final AdminCalendarioController controller;

  @override
  Widget build(BuildContext context) {
    const alto = 16 * AppSizes.calendarioAltoHora;
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 64),
            for (final dia in controller.diasSemana)
              SizedBox(
                width: AppSizes.calendarioAnchoColumnaMin,
                child: Text(
                  '${_nombreDia(dia.weekday)} ${dia.day}',
                  style: AppTextStyles.label.copyWith(
                    color: controller.esHoy(dia) ? AppColors.primary : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.space8),
        SizedBox(
          height: alto,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: alto,
                child: Stack(
                  children: [
                    for (var hora = 6; hora <= 22; hora++)
                      Positioned(
                        top: (hora - 6) * AppSizes.calendarioAltoHora,
                        child: Text(minutosATexto(hora * 60)),
                      ),
                  ],
                ),
              ),
              for (final dia in controller.diasSemana)
                _Columna(controller: controller, dia: dia, alto: alto),
            ],
          ),
        ),
      ],
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({
    required this.controller,
    required this.dia,
    required this.alto,
  });

  final AdminCalendarioController controller;
  final DateTime dia;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final bloques = controller.bloquesDe(dia.weekday);
    final libres = controller.huecosLibres(dia.weekday);
    final carriles = _carriles(bloques, controller.canchaId == null);
    return Container(
      width: AppSizes.calendarioAnchoColumnaMin,
      height: alto,
      decoration: BoxDecoration(
        color: controller.esHoy(dia)
            ? AppColors.primary.withValues(alpha: 0.06)
            : null,
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          for (final libre in libres)
            _posicion(
              libre.inicio,
              libre.fin,
              0,
              1,
              AppColors.success.withValues(alpha: 0.25),
              AppStrings.adminCalendarioLibre,
              false,
              '',
            ),
          for (final item in carriles)
            _posicion(
              item.bloque.inicio,
              item.bloque.fin,
              item.carril,
              item.total,
              item.bloque.tipo == TipoReserva.evento
                  ? AppColors.primary
                  : AppColors.navy,
              item.bloque.titulo,
              controller.canchaId == null,
              item.bloque.canchaNombre,
            ),
        ],
      ),
    );
  }

  Widget _posicion(
    int inicio,
    int fin,
    int carril,
    int total,
    Color color,
    String titulo,
    bool mostrarCancha,
    String cancha,
  ) {
    final top =
        (inicio - AdminCalendarioController.jornadaInicio) /
        60 *
        AppSizes.calendarioAltoHora;
    final height = (fin - inicio) / 60 * AppSizes.calendarioAltoHora;
    final ancho = AppSizes.calendarioAnchoColumnaMin / total;
    final horas = '${minutosATexto(inicio)}–${minutosATexto(fin)}';
    final detalle = mostrarCancha ? '$titulo\n$horas\n$cancha' : '$titulo\n$horas';
    return Positioned(
      top: top,
      height: height,
      left: carril * ancho,
      width: ancho,
      child: Tooltip(
        message: detalle,
        child: Container(
          key: ValueKey(titulo),
          color: color,
          padding: const EdgeInsets.all(AppSizes.space4),
          child: Text(
            detalle,
            style: AppTextStyles.bodySmall.copyWith(
              color: color == AppColors.success.withValues(alpha: 0.25)
                  ? AppColors.navy
                  : AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _EnCarril {
  const _EnCarril(this.bloque, this.carril, this.total);

  final BloqueOcupado bloque;
  final int carril;
  final int total;
}

List<_EnCarril> _carriles(List<BloqueOcupado> bloques, bool ladoALado) {
  if (!ladoALado) {
    return [for (final bloque in bloques) _EnCarril(bloque, 0, 1)];
  }
  final carrilDe = <BloqueOcupado, int>{};
  final finCarril = <int>[];
  for (final bloque in bloques) {
    var carril = finCarril.indexWhere((fin) => fin <= bloque.inicio);
    if (carril == -1) {
      carril = finCarril.length;
      finCarril.add(bloque.fin);
    } else {
      finCarril[carril] = bloque.fin;
    }
    carrilDe[bloque] = carril;
  }
  final total = finCarril.isEmpty ? 1 : finCarril.length;
  return [
    for (final bloque in bloques) _EnCarril(bloque, carrilDe[bloque]!, total),
  ];
}

String _nombreDia(int dia) {
  final nombre = AppStrings.entDiasSemana[dia - 1];
  return '${nombre[0].toUpperCase()}${nombre.substring(1)}';
}

String _tipo(TipoReserva tipo) {
  return tipo == TipoReserva.evento
      ? AppStrings.adminCalendarioEvento
      : AppStrings.adminCalendarioDeporte;
}
