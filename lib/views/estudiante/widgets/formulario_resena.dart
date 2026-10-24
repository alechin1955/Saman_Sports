import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/comunidad_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/views/estudiante/widgets/selector_estrellas.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

/// Formulario para publicar una reseña nueva o editar una propia.
/// Si [inicial] es null publica; si no, edita esa reseña y cierra el diálogo.
class FormularioResena extends StatefulWidget {
  const FormularioResena({super.key, required this.controller, this.inicial});

  final ComunidadController controller;
  final Resena? inicial;

  @override
  State<FormularioResena> createState() => _FormularioResenaState();
}

class _FormularioResenaState extends State<FormularioResena> {
  late final TextEditingController _comentario = TextEditingController(
    text: widget.inicial?.comentario ?? '',
  );
  late int _estrellas = widget.inicial?.estrellas ?? 0;
  String? _deporteId;

  bool get _editando => widget.inicial != null;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final c = widget.controller;

    if (_editando) {
      final ok = await c.editar(
        widget.inicial!,
        estrellas: _estrellas,
        comentario: _comentario.text,
      );
      if (!mounted || !ok) return;
      Navigator.pop(context, true);
      return;
    }

    final deporte = c.deportes.where((d) => d.id == _deporteId).firstOrNull;
    final ok = await c.publicar(
      deporte: deporte,
      estrellas: _estrellas,
      comentario: _comentario.text,
    );
    if (!mounted || !ok) return;
    setState(() {
      _deporteId = null;
      _estrellas = 0;
      _comentario.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text(AppStrings.resenaPublicada),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.disciplina, style: AppTextStyles.label),
            const SizedBox(height: AppSizes.space8),
            if (_editando)
              Text(widget.inicial!.disciplina, style: AppTextStyles.subtitle)
            else
              Wrap(
                spacing: AppSizes.space8,
                runSpacing: AppSizes.space8,
                children: [
                  for (final deporte in c.deportes)
                    _OpcionDisciplina(
                      texto: deporte.nombre,
                      activa: deporte.id == _deporteId,
                      onTap: () => setState(() => _deporteId = deporte.id),
                    ),
                ],
              ),
            const SizedBox(height: AppSizes.space16),
            Text(AppStrings.calificacion, style: AppTextStyles.label),
            const SizedBox(height: AppSizes.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: SelectorEstrellas(
                valor: _estrellas,
                onChanged: (valor) => setState(() => _estrellas = valor),
              ),
            ),
            const SizedBox(height: AppSizes.space12),
            Text(AppStrings.comentario, style: AppTextStyles.label),
            const SizedBox(height: AppSizes.space8),
            TextField(
              controller: _comentario,
              minLines: 3,
              maxLines: 5,
              maxLength: ComunidadController.maximoComentario,
              decoration: const InputDecoration(
                hintText: AppStrings.hintComentario,
              ),
            ),
            const SizedBox(height: AppSizes.space12),
            if (c.errorFormulario != null) ...[
              MensajeError(texto: c.errorFormulario!),
              const SizedBox(height: AppSizes.space12),
            ],
            BotonPrimario(
              texto: _editando ? AppStrings.guardar : AppStrings.publicarResena,
              cargando: c.enviando,
              anchoCompleto: true,
              onPressed: _enviar,
            ),
          ],
        );
      },
    );
  }
}

class _OpcionDisciplina extends StatelessWidget {
  const _OpcionDisciplina({
    required this.texto,
    required this.activa,
    required this.onTap,
  });

  final String texto;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: activa,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      label: Text(texto),
      labelStyle: AppTextStyles.label.copyWith(
        color: activa ? AppColors.primary : AppColors.navy,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(color: activa ? AppColors.primary : AppColors.border),
    );
  }
}
