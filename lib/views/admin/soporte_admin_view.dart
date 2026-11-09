import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_soporte_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class SoporteAdminView extends StatelessWidget {
  const SoporteAdminView({super.key, required this.soporte});

  final AdminSoporteController soporte;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: soporte,
      builder: (context, _) {
        final lista = soporte.ticketsFiltrados;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              children: [
                ChoiceChip(
                  label: Text(AppStrings.adminAbiertos),
                  selected: soporte.filtro == EstadoTicket.abierto,
                  onSelected: (_) =>
                      soporte.cambiarFiltro(EstadoTicket.abierto),
                ),
                ChoiceChip(
                  label: Text(AppStrings.adminResueltos),
                  selected: soporte.filtro == EstadoTicket.resuelto,
                  onSelected: (_) =>
                      soporte.cambiarFiltro(EstadoTicket.resuelto),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (soporte.error != null)
              Text(
                soporte.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (soporte.cargando && lista.isEmpty)
              const CircularProgressIndicator()
            else if (lista.isEmpty)
              Text(AppStrings.adminSinTickets, style: AppTextStyles.body)
            else
              for (final ticket in lista)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket.asunto, style: AppTextStyles.subtitle),
                        Text(
                          ticket.categoriaVisible,
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          '${ticket.autorNombre} · ${ticket.autorRol} · ${_fecha(ticket.fecha)}',
                        ),
                        const SizedBox(height: AppSizes.space8),
                        Text(ticket.descripcion),
                        if (ticket.estado == EstadoTicket.resuelto) ...[
                          const SizedBox(height: AppSizes.space8),
                          Text(
                            '${AppStrings.adminRespuesta}: ${ticket.respuesta}',
                          ),
                          if (ticket.resueltoEn != null)
                            Text(
                              '${AppStrings.adminFecha}: ${_fecha(ticket.resueltoEn!)}',
                            ),
                        ],
                        if (ticket.estado == EstadoTicket.abierto)
                          TextButton(
                            onPressed: () => _responder(context, ticket),
                            child: Text(AppStrings.adminSolventar),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _responder(BuildContext context, TicketSoporte ticket) async {
    final respuesta = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: soporte,
        builder: (context, _) {
          final guardando = soporte.guardando;
          return AlertDialog(
            title: Text(AppStrings.adminSolventar),
            content: CampoTexto(
              label: AppStrings.adminRespuesta,
              controller: respuesta,
            ),
            actions: [
              if (soporte.error != null)
                Text(
                  soporte.error!,
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                ),
              BotonSecundario(
                texto: AppStrings.cancelar,
                onPressed: guardando ? null : () => Navigator.pop(dialogContext),
              ),
              BotonPrimario(
                texto: AppStrings.guardar,
                cargando: guardando,
                onPressed: guardando
                    ? null
                    : () async {
                        if (soporte.guardando) return;
                        final error = await soporte.responder(
                          ticket,
                          respuesta.text,
                        );
                        if (!dialogContext.mounted || error != null) return;
                        Navigator.pop(dialogContext);
                      },
              ),
            ],
          );
        },
      ),
    );
    respuesta.dispose();
  }
}

String _fecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year} $hora:$minuto';
}
