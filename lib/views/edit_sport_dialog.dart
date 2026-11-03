import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/sport_model.dart';
import '../controllers/sport_controller.dart';
import '../models/entrenador_model.dart';
import '../repositories/entrenador_repository.dart';

class EditSportDialog extends StatefulWidget {
  final SportModel sport;
  const EditSportDialog({super.key, required this.sport});

  @override
  State<EditSportDialog> createState() => _EditSportDialogState();
}

class _EditSportDialogState extends State<EditSportDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _horarioController;
  late TextEditingController _cuposController;
  
  final SportController _controller = SportController();
  bool _isLoading = false;
  String? _selectedEntrenadorId;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.sport.nombre);
    _horarioController = TextEditingController(text: widget.sport.horario);
    _cuposController = TextEditingController(text: widget.sport.cuposTotales.toString());
    
    if (widget.sport.entrenadorId != 'sin_asignar') {
      _selectedEntrenadorId = widget.sport.entrenadorId;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _horarioController.dispose();
    _cuposController.dispose();
    super.dispose();
  }

  Future<void> _actualizarDeporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cuposNuevos = int.parse(_cuposController.text.trim());
    
    final updatedSport = widget.sport.copyWith(
      nombre: _nombreController.text.trim(),
      horario: _horarioController.text.trim(),
      cuposTotales: cuposNuevos,
      cuposDisponibles: cuposNuevos > widget.sport.cuposTotales 
          ? widget.sport.cuposDisponibles + (cuposNuevos - widget.sport.cuposTotales)
          : widget.sport.cuposDisponibles,
      entrenadorId: _selectedEntrenadorId,
    );

    final exito = await _controller.updateSport(updatedSport);

    if (mounted) {
      setState(() => _isLoading = false);
      if (exito) {
        Navigator.pop(context, true);
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
      title: const Text('Editar Deporte', style: TextStyle(color: AppColors.navy)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _horarioController,
                decoration: const InputDecoration(labelText: 'Horario', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cuposController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cupos Totales', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  if (int.tryParse(val) == null) return 'Debe ser número';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<EntrenadorModel>>(
                future: EntrenadorRepository().getEntrenadores(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Registra entrenadores primero.', style: TextStyle(color: Colors.red));
                  }

                  final entrenadores = snapshot.data!;
                  final entrenadorExiste = entrenadores.any((e) => e.id == _selectedEntrenadorId);
                  if (!entrenadorExiste) _selectedEntrenadorId = null;

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Reasignar Entrenador', border: OutlineInputBorder()),
                    value: _selectedEntrenadorId,
                    items: entrenadores.map((entrenador) {
                      return DropdownMenuItem<String>(
                        value: entrenador.id,
                        child: Text(entrenador.nombre),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedEntrenadorId = value),
                    validator: (val) => val == null ? 'Seleccione un entrenador' : null,
                  );
                },
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
          onPressed: _isLoading ? null : _actualizarDeporte,
          child: _isLoading 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Actualizar'),
        ),
      ],
    );
  }
}