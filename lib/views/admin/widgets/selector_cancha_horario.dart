import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/reserva_horario.dart';

class SelectorCanchaHorario extends StatefulWidget {
  const SelectorCanchaHorario({
    super.key,
    required this.canchas,
    required this.canchaId,
    required this.franjas,
    required this.reservasCancha,
    required this.onCanchaChanged,
    required this.onFranjasChanged,
    this.onFechaChanged,
    this.ignorarRefId,
    this.modoFecha = false,
    this.fecha,
  });

  final List<Cancha> canchas;
  final String? canchaId;
  final List<FranjaHorario> franjas;
  final List<ReservaHorario> reservasCancha;
  final ValueChanged<String?> onCanchaChanged;
  final ValueChanged<List<FranjaHorario>> onFranjasChanged;
  final ValueChanged<String?>? onFechaChanged;
  final String? ignorarRefId;
  final bool modoFecha;
  final String? fecha;

  @override
  State<SelectorCanchaHorario> createState() => _SelectorCanchaHorarioState();
}

class _SelectorCanchaHorarioState extends State<SelectorCanchaHorario> {
  final Set<int> _dias = {};
  int _inicio = 960;
  int _fin = 1080;

  List<int> get _horas => [
    for (var minuto = 0; minuto <= 1440; minuto += 15) minuto,
  ];

  String? get _error {
    final borrador = _borrador();
    for (final franja in [...widget.franjas, ...borrador]) {
      final invalida = validarFranja(franja);
      if (invalida != null && borrador.contains(franja)) return invalida;
    }
    if (borrador.isEmpty && widget.franjas.isEmpty) return null;
    final choque = buscarChoque(
      nuevas: [
        for (final franja in [...widget.franjas, ...borrador]) _reserva(franja),
      ],
      existentes: widget.reservasCancha,
      ignorarRefId: widget.ignorarRefId,
    );
    return choque == null ? null : mensajeChoque(choque);
  }

  List<FranjaHorario> _borrador() {
    if (widget.modoFecha) {
      final fecha = widget.fecha;
      if (fecha == null || fecha.isEmpty) return const [];
      final dia = DateTime.tryParse(fecha)?.weekday;
      if (dia == null) return const [];
      return [FranjaHorario(dia: dia, horaInicio: _inicio, horaFin: _fin)];
    }
    return [
      for (final dia in _dias)
        FranjaHorario(dia: dia, horaInicio: _inicio, horaFin: _fin),
    ];
  }

  ReservaHorario _reserva(FranjaHorario franja) {
    final cancha = widget.canchas.cast<Cancha?>().firstWhere(
      (item) => item?.id == widget.canchaId,
      orElse: () => null,
    );
    return ReservaHorario(
      id: '',
      canchaId: widget.canchaId ?? '',
      canchaNombre: cancha?.nombre ?? '',
      dia: franja.dia,
      horaInicio: franja.horaInicio,
      horaFin: franja.horaFin,
      fecha: widget.modoFecha ? widget.fecha : null,
      tipo: widget.modoFecha ? TipoReserva.evento : TipoReserva.deporte,
      refId: widget.ignorarRefId ?? '',
      refNombre: '',
      activa: true,
    );
  }

  Future<void> _elegirHora(bool inicio) async {
    final actual = inicio ? _inicio : _fin;
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: actual ~/ 60, minute: actual % 60),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (elegida == null) return;
    final minutos = ((elegida.minute / 15).round() * 15).clamp(0, 60);
    final total = (elegida.hour * 60 + minutos).clamp(0, 1440);
    setState(() {
      if (inicio) {
        _inicio = total;
      } else {
        _fin = total;
      }
    });
  }

  void _agregar() {
    final nuevas = _borrador();
    if (nuevas.isEmpty) return;
    widget.onFranjasChanged([...widget.franjas, ...nuevas]);
    setState(_dias.clear);
  }

  @override
  Widget build(BuildContext context) {
    final cancha = widget.canchas.cast<Cancha?>().firstWhere(
      (item) => item?.id == widget.canchaId,
      orElse: () => null,
    );
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: widget.canchaId,
          decoration: InputDecoration(labelText: AppStrings.adminCancha),
          items: [
            for (final item in widget.canchas.where((c) => c.activa))
              DropdownMenuItem(value: item.id, child: Text(item.nombre)),
          ],
          onChanged: widget.onCanchaChanged,
        ),
        const SizedBox(height: AppSizes.space12),
        if (widget.modoFecha)
          OutlinedButton(
            onPressed: () async {
              final elegida = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate:
                    DateTime.tryParse(widget.fecha ?? '') ?? DateTime.now(),
              );
              if (elegida == null) return;
              final mes = elegida.month.toString().padLeft(2, '0');
              final dia = elegida.day.toString().padLeft(2, '0');
              widget.onFechaChanged?.call('${elegida.year}-$mes-$dia');
            },
            child: Text(widget.fecha ?? AppStrings.adminFecha),
          )
        else
          Wrap(
            spacing: AppSizes.space8,
            children: [
              for (var dia = 1; dia <= 7; dia++)
                FilterChip(
                  label: Text(abreviaturasDias[dia - 1]),
                  selected: _dias.contains(dia),
                  onSelected: (activo) {
                    setState(() {
                      if (activo) {
                        _dias.add(dia);
                      } else {
                        _dias.remove(dia);
                      }
                    });
                  },
                ),
            ],
          ),
        const SizedBox(height: AppSizes.space12),
        Wrap(
          spacing: AppSizes.space8,
          runSpacing: AppSizes.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Hora(
              clave: const Key('hora-inicio'),
              label: AppStrings.adminHoraInicio,
              valor: _inicio,
              horas: _horas,
              onChanged: (valor) => setState(() => _inicio = valor),
            ),
            _Hora(
              clave: const Key('hora-fin'),
              label: AppStrings.adminHoraFin,
              valor: _fin,
              horas: _horas,
              onChanged: (valor) => setState(() => _fin = valor),
            ),
            TextButton(
              onPressed: () => _elegirHora(true),
              child: Text(AppStrings.adminElegirHora),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space8),
        TextButton(
          onPressed: _agregar,
          child: Text(AppStrings.adminAgregarHorario),
        ),
        if (error != null)
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        if (widget.franjas.isNotEmpty)
          Text(textoHorario(widget.franjas, cancha: cancha?.nombre)),
        const SizedBox(height: AppSizes.space12),
        Text(
          '${AppStrings.adminOcupacionDe} ${cancha?.nombre ?? AppStrings.adminCancha}',
          style: AppTextStyles.label,
        ),
        for (final reserva in widget.reservasCancha)
          Text(
            '${abreviaturasDias[reserva.dia - 1]} ${minutosATexto(reserva.horaInicio)}–${minutosATexto(reserva.horaFin)} · ${reserva.refNombre} (${reserva.tipo.valor})',
            style: AppTextStyles.bodySmall,
          ),
        for (var i = 0; i < widget.franjas.length; i++)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${abreviaturasDias[widget.franjas[i].dia - 1]} ${minutosATexto(widget.franjas[i].horaInicio)}',
                ),
              ),
              TextButton(
                onPressed: () {
                  final copia = [...widget.franjas]..removeAt(i);
                  widget.onFranjasChanged(copia);
                },
                child: Text(AppStrings.adminQuitarHorario),
              ),
            ],
          ),
      ],
    );
  }
}

class _Hora extends StatelessWidget {
  const _Hora({
    required this.clave,
    required this.label,
    required this.valor,
    required this.horas,
    required this.onChanged,
  });

  final Key clave;
  final String label;
  final int valor;
  final List<int> horas;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: clave,
      width: 160,
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label-$valor'),
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final hora in horas)
            DropdownMenuItem(value: hora, child: Text(minutosATexto(hora))),
        ],
        onChanged: (valor) {
          if (valor != null) onChanged(valor);
        },
      ),
    );
  }
}
