import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_pago_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/repositories/admin/admin_solvencia.dart';
import 'package:saman_sports/views/admin/widgets/grafico_barras.dart';
import 'package:saman_sports/views/admin/widgets/tarjeta_resumen.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class PagosAdminView extends StatefulWidget {
  const PagosAdminView({super.key, required this.pagos});

  final AdminPagoController pagos;

  @override
  State<PagosAdminView> createState() => _PagosAdminViewState();
}

class _PagosAdminViewState extends State<PagosAdminView> {
  final TextEditingController _periodo = TextEditingController();
  final TextEditingController _monto = TextEditingController();
  DateTime? _inicio;
  DateTime? _corte;
  var _copiado = false;

  @override
  void dispose() {
    _periodo.dispose();
    _monto.dispose();
    super.dispose();
  }

  void _copiar(ConfiguracionPagos? config) {
    if (_copiado || config == null) return;
    _copiado = true;
    _periodo.text = config.periodo;
    _monto.text = config.monto.toString();
    _inicio = config.fechaInicio;
    _corte = config.fechaCorte;
  }

  bool _corteVencido(ConfiguracionPagos? config) {
    if (config == null || widget.pagos.guardando) return false;
    return AdminSolvencia.corteVencido(DateTime.now(), config.fechaCorte);
  }

  int _dias(ConfiguracionPagos? config) {
    if (config == null) return 0;
    final hoy = DateTime.now();
    final corte = DateTime(
      config.fechaCorte.year,
      config.fechaCorte.month,
      config.fechaCorte.day,
    );
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final dias = corte.difference(inicio).inDays;
    return dias < 0 ? 0 : dias;
  }

  Future<void> _elegir(bool inicio) async {
    final actual = inicio ? _inicio : _corte;
    final elegida = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: actual ?? DateTime.now(),
    );
    if (elegida == null) return;
    setState(() {
      if (inicio) {
        _inicio = elegida;
      } else {
        _corte = elegida;
      }
    });
  }

  Future<void> _guardar() async {
    final inicio = _inicio;
    final corte = _corte;
    final monto = double.tryParse(_monto.text.trim().replaceAll(',', '.'));
    if (inicio == null || corte == null || monto == null) return;
    await widget.pagos.guardarFechaCorte(
      periodo: _periodo.text.trim(),
      fechaInicio: inicio,
      fechaCorte: corte,
      monto: monto,
    );
  }

  Future<void> _aplicar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.adminAplicarCorte),
        content: Text(AppStrings.adminConfirmarCorte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.adminAplicarCorte),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await widget.pagos.aplicarCorte();
    if (!mounted) return;
    final texto = error ?? widget.pagos.mensaje;
    if (texto == null || texto.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.pagos,
      builder: (context, _) {
        final config = widget.pagos.configuracion;
        if (!_copiado && config != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _copiar(config));
          });
        }
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        final columna = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.adminFechaCorte,
                      style: AppTextStyles.subtitle,
                    ),
                    CampoTexto(
                      label: AppStrings.adminPeriodo,
                      controller: _periodo,
                    ),
                    Wrap(
                      spacing: AppSizes.space8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _elegir(true),
                          child: Text(
                            _inicio == null
                                ? AppStrings.adminFechaInicio
                                : _dia(_inicio!),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _elegir(false),
                          child: Text(
                            _corte == null
                                ? AppStrings.adminFechaCorte
                                : _dia(_corte!),
                          ),
                        ),
                      ],
                    ),
                    CampoTexto(
                      label: AppStrings.adminMonto,
                      controller: _monto,
                      keyboardType: TextInputType.number,
                    ),
                    Text(
                      '${AppStrings.adminDiasCorte}: ${_dias(config)}',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSizes.space8),
                    BotonPrimario(
                      texto: AppStrings.guardar,
                      cargando: widget.pagos.guardando,
                      onPressed: _guardar,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space16),
            if (widget.pagos.verificacionSimulada)
              Tooltip(
                message: AppStrings.adminVerificacionPaypalAyuda,
                child: Text(
                  AppStrings.adminVerificacionPaypalSimulada,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            const SizedBox(height: AppSizes.space8),
            _Estadisticas(panel: widget.pagos),
            const SizedBox(height: AppSizes.space12),
            GraficoBarras(
              titulo: AppStrings.adminEstadoPagos,
              barras: _barrasPagos(widget.pagos),
            ),
            const SizedBox(height: AppSizes.space8),
            BotonPrimario(
              texto: AppStrings.adminAplicarCorte,
              onPressed: _corteVencido(config) ? _aplicar : null,
            ),
            const SizedBox(height: AppSizes.space16),
            if (widget.pagos.error != null)
              Text(
                widget.pagos.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (widget.pagos.pagosFiltrados.isEmpty)
              Text(AppStrings.adminSinPagos, style: AppTextStyles.body)
            else if (movil)
              for (final pago in widget.pagos.pagosFiltrados)
                _PagoTile(pago: pago, panel: widget.pagos)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(AppStrings.adminEstudiante)),
                    DataColumn(label: Text(AppStrings.adminMonto)),
                    DataColumn(label: Text(AppStrings.adminIdPaypal)),
                    DataColumn(label: Text(AppStrings.adminFechaPago)),
                    DataColumn(label: Text(AppStrings.adminEstado)),
                    DataColumn(label: Text(AppStrings.adminPagoPendienteEtiqueta)),
                    DataColumn(label: Text(AppStrings.adminVerificado)),
                    DataColumn(label: Text(AppStrings.adminVerificadoPor)),
                    DataColumn(label: Text(AppStrings.editar)),
                  ],
                  rows: [
                    for (final pago in widget.pagos.pagosFiltrados)
                      DataRow(
                        cells: [
                          DataCell(Text(_estudiante(widget.pagos, pago))),
                          DataCell(Text(pago.monto.toString())),
                          DataCell(Text(_idPaypal(pago))),
                          DataCell(Text(_fechaPago(pago))),
                          DataCell(Text(_estadoPago(pago.estado))),
                          DataCell(Text(_puntualidad(widget.pagos, pago))),
                          DataCell(
                            _IconoVerificado(verificado: pago.verificado),
                          ),
                          DataCell(
                            Text(
                              pago.verificadoPor.isEmpty
                                  ? AppStrings.adminSinDato
                                  : pago.verificadoPor,
                            ),
                          ),
                          DataCell(
                            _AccionesPago(pago: pago, panel: widget.pagos),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedHeight) return columna;
            return SingleChildScrollView(child: columna);
          },
        );
      },
    );
  }
}

class _PagoTile extends StatelessWidget {
  const _PagoTile({required this.pago, required this.panel});

  final Pago pago;
  final AdminPagoController panel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_estudiante(panel, pago), style: AppTextStyles.subtitle),
            Text('${pago.monto} · ${_idPaypal(pago)}'),
            Text(
              '${_fechaPago(pago)} · ${_estadoPago(pago.estado)} · ${_puntualidad(panel, pago)}',
            ),
            _IconoVerificado(verificado: pago.verificado),
            _AccionesPago(pago: pago, panel: panel),
          ],
        ),
      ),
    );
  }
}

class _IconoVerificado extends StatelessWidget {
  const _IconoVerificado({required this.verificado});

  final bool verificado;

  @override
  Widget build(BuildContext context) {
    return Icon(
      verificado ? Icons.verified : Icons.hourglass_empty,
      color: verificado ? AppColors.success : AppColors.textSecondary,
    );
  }
}

String _estudiante(AdminPagoController panel, Pago pago) {
  for (final estudiante in panel.estudiantes) {
    if (estudiante.uid == pago.estudianteUid) return estudiante.nombreCompleto;
  }
  return pago.estudianteUid;
}

String _idPaypal(Pago pago) {
  if (pago.paypalOrderId.isNotEmpty) return pago.paypalOrderId;
  if (pago.idTransaccion.isNotEmpty) return pago.idTransaccion;
  return AppStrings.adminSinDato;
}

String _fechaPago(Pago pago) {
  final fecha = pago.fechaPago;
  if (fecha == null) return AppStrings.adminSinDato;
  return _diaHora(fecha);
}

String _puntualidad(AdminPagoController panel, Pago pago) {
  final config = panel.configuracion;
  if (config == null) return AppStrings.adminPagoPendienteEtiqueta;
  return switch (AdminPagoController.puntualidad(pago, config)) {
    AdminPuntualidad.aTiempo => AppStrings.adminATiempo,
    AdminPuntualidad.tardio => AppStrings.adminTardio,
    AdminPuntualidad.pendiente => AppStrings.adminPagoPendienteEtiqueta,
  };
}

String _estadoPago(EstadoPago estado) {
  return switch (estado) {
    EstadoPago.pendiente => AppStrings.adminPendientes,
    EstadoPago.realizado => AppStrings.adminRealizado,
    EstadoPago.rechazado => AppStrings.adminRechazados,
  };
}

class _AccionesPago extends StatelessWidget {
  const _AccionesPago({required this.pago, required this.panel});

  final Pago pago;
  final AdminPagoController panel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        if (!pago.verificado)
          TextButton(
            onPressed: panel.guardando ? null : () => panel.verificarPago(pago),
            child: Text(AppStrings.adminVerificarPaypal),
          ),
        if (pago.estado != EstadoPago.rechazado)
          TextButton(
            onPressed: panel.guardando
                ? null
                : () => _confirmar(
                    context,
                    AppStrings.adminConfirmarRechazarPago,
                    () => panel.rechazarPago(pago),
                  ),
            child: Text(AppStrings.adminRechazar),
          ),
        if (pago.estado != EstadoPago.pendiente)
          TextButton(
            onPressed: panel.guardando
                ? null
                : () => _confirmar(
                    context,
                    AppStrings.adminConfirmarPendientePago,
                    () => panel.marcarPendiente(pago),
                  ),
            child: Text(AppStrings.adminMarcarPendiente),
          ),
      ],
    );
  }

  Future<void> _confirmar(
    BuildContext context,
    String titulo,
    Future<String?> Function() accion,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.adminConfirmar),
          ),
        ],
      ),
    );
    if (ok == true) await accion();
  }
}

class _Estadisticas extends StatelessWidget {
  const _Estadisticas({required this.panel});

  final AdminPagoController panel;

  @override
  Widget build(BuildContext context) {
    final pagos = panel.pagos;
    final verificados = pagos.where((pago) => pago.verificado).length;
    final pendientes = pagos
        .where((pago) => pago.estado == EstadoPago.pendiente)
        .length;
    final rechazados = pagos
        .where((pago) => pago.estado == EstadoPago.rechazado)
        .length;
    final monto = pagos
        .where((pago) => pago.verificado)
        .fold<double>(0, (suma, pago) => suma + pago.monto);
    final tarjetas = [
      (AppStrings.adminTotal, '${pagos.length}'),
      (AppStrings.adminVerificados, '$verificados'),
      (AppStrings.adminPendientes, '$pendientes'),
      (AppStrings.adminRechazados, '$rechazados'),
      (AppStrings.adminMontoRecaudado, '\$${monto.toStringAsFixed(2)}'),
    ];
    return Wrap(
      spacing: AppSizes.space12,
      runSpacing: AppSizes.space12,
      children: [
        for (final tarjeta in tarjetas)
          SizedBox(
            width: 180,
            child: TarjetaResumen(
              icono: Icons.payments_outlined,
              titulo: tarjeta.$1,
              valor: tarjeta.$2,
            ),
          ),
      ],
    );
  }
}

List<BarraGrafico> _barrasPagos(AdminPagoController panel) {
  final pagos = panel.pagos;
  return [
    BarraGrafico(
      etiqueta: AppStrings.adminVerificados,
      valor: pagos.where((pago) => pago.verificado).length,
    ),
    BarraGrafico(
      etiqueta: AppStrings.adminPendientes,
      valor: pagos.where((pago) => pago.estado == EstadoPago.pendiente).length,
    ),
    BarraGrafico(
      etiqueta: AppStrings.adminRechazados,
      valor: pagos.where((pago) => pago.estado == EstadoPago.rechazado).length,
    ),
  ];
}

String _dia(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

String _diaHora(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${_dia(fecha)} $hora:$minuto';
}
