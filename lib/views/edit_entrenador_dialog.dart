import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/entrenador_model.dart';
import '../controllers/entrenador_controller.dart';

class EditEntrenadorDialog extends StatefulWidget {
  final EntrenadorModel entrenador;
  const EditEntrenadorDialog({super.key, required this.entrenador});

  @override
  State<EditEntrenadorDialog> createState() => _EditEntrenadorDialogState();
}

class _EditEntrenadorDialogState extends State<EditEntrenadorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _especialidadController;
  late TextEditingController _experienciaController;
  
  final EntrenadorController _controller = EntrenadorController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos los campos con los datos actuales
    _nombreController = TextEditingController(text: widget.entrenador.nombre);
    _correoController = TextEditingController(text: widget.entrenador.correo);
    _especialidadController = TextEditingController(text: widget.entrenador.especialidad);
    _experienciaController = TextEditingController(text: widget.entrenador.anosExperiencia.toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _especialidadController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  Future<void> _actualizarEntrenador() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedEntrenador = widget.entrenador.copyWith(
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      especialidad: _especialidadController.text.trim(),
      anosExperiencia: int.parse(_experienciaController.text.trim()),
    );

    final exito = await _controller.updateEntrenador(updatedEntrenador);

    if (mounted) {
      setState(() => _isLoading = false);
      if (exito) {
        Navigator.pop(context, true); // Retorna true para actualizar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Entrenador', style: TextStyle(color: AppColors.navy)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // La cédula generalmente no se edita porque es el identificador, la mostramos como texto
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text('C.I: ${widget.entrenador.cedula}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                validator: (val) => val == null || !val.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _especialidadController,
                decoration: const InputDecoration(labelText: 'Especialidad', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienciaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Años de Experiencia', border: OutlineInputBorder()),
                validator: (val) => val == null || int.tryParse(val) == null ? 'Debe ser un número' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _actualizarEntrenador,
          child: _isLoading 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}