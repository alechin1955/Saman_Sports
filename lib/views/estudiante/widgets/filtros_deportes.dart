import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

/// Buscador y filtros de "Explorar deportes": texto, solo con cupos y día.
class FiltrosDeportes extends StatefulWidget {
  const FiltrosDeportes({super.key, required this.controller});

  final ExplorarDeportesController controller;

  @override
  State<FiltrosDeportes> createState() => _FiltrosDeportesState();
}

class _FiltrosDeportesState extends State<FiltrosDeportes> {
  late final TextEditingController _texto = TextEditingController(
    text: widget.controller.busqueda,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sincronizar);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sincronizar);
    _texto.dispose();
    super.dispose();
  }

  /// Si el controlador limpia la búsqueda, el campo también se limpia.
  void _sincronizar() {
    if (_texto.text != widget.controller.busqueda) {
      _texto.text = widget.controller.busqueda;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _texto,
          onChanged: c.buscar,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppStrings.buscarDeportesHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: c.busqueda.isEmpty
                ? null
                : IconButton(
                    tooltip: AppStrings.limpiarFiltros,
                    icon: const Icon(Icons.close),
                    onPressed: () => c.buscar(''),
                  ),
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        Wrap(
          spacing: AppSizes.space8,
          runSpacing: AppSizes.space8,
          children: [
            _Filtro(
              texto: AppStrings.soloConCupos,
              icono: Icons.event_available_outlined,
              activo: c.soloConCupos,
              onTap: () => c.cambiarSoloConCupos(!c.soloConCupos),
            ),
            _Filtro(
              texto: AppStrings.todosLosDias,
              activo: c.dia == null,
              onTap: () => c.elegirDia(null),
            ),
            for (final dia in ExplorarDeportesController.dias)
              _Filtro(
                texto: dia,
                activo: c.dia == dia,
                onTap: () => c.elegirDia(dia),
              ),
          ],
        ),
      ],
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.texto,
    required this.activo,
    required this.onTap,
    this.icono,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.primary : AppColors.navy;
    return FilterChip(
      selected: activo,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      avatar: icono == null
          ? null
          : Icon(icono, size: AppSizes.iconSmall, color: color),
      label: Text(texto),
      labelStyle: AppTextStyles.label.copyWith(color: color),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(color: activo ? AppColors.primary : AppColors.border),
    );
  }
}
