import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_sizes.dart';
import '../controllers/sport_controller.dart';
import '../models/entrenador_model.dart';
import '../repositories/entrenador_repository.dart';

class NewSportView extends StatefulWidget {
  const NewSportView({super.key});

  @override
  State<NewSportView> createState() => _NewSportViewState();
}

class _NewSportViewState extends State<NewSportView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _horarioController = TextEditingController();
  final _cuposController = TextEditingController();
  
  final SportController _controller = SportController();
  bool _isLoading = false;
  String? _selectedEntrenadorId; // Variable para almacenar el entrenador seleccionado

  @override
  void dispose() {
    _nombreController.dispose();
    _horarioController.dispose();
    _cuposController.dispose();
    super.dispose();
  }

  Future<void> _guardarDeporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final exito = await _controller.createSport(
      nombre: _nombreController.text.trim(),
      cupos: int.parse(_cuposController.text.trim()),
      horario: _horarioController.text.trim(),
      entrenadorId: _selectedEntrenadorId!, // Enviamos el ID seleccionado
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deporte registrado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Revisa la consola.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Deporte'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              margin: const EdgeInsets.all(AppSizes.space24),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre del Deporte', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSizes.space16),
                      TextFormField(
                        controller: _horarioController,
                        decoration: const InputDecoration(labelText: 'Horario (ej. Lunes 14:00 - 16:00)', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSizes.space16),
                      TextFormField(
                        controller: _cuposController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cupos Totales', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          if (int.tryParse(val) == null) return 'Debe ser un número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.space16),
                      
                      // --- NUEVO: SELECTOR DE ENTRENADOR ---
                      FutureBuilder<List<EntrenadorModel>>(
                        future: EntrenadorRepository().getEntrenadores(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No hay entrenadores registrados. Registra uno primero.', style: TextStyle(color: Colors.red));
                          }

                          final entrenadores = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Entrenador Asignado',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedEntrenadorId,
                            items: entrenadores.map((entrenador) {
                              return DropdownMenuItem<String>(
                                value: entrenador.id,
                                child: Text('${entrenador.nombre} (${entrenador.especialidad})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedEntrenadorId = value;
                              });
                            },
                            validator: (val) => val == null ? 'Seleccione un entrenador' : null,
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.space24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.space16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _guardarDeporte,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Guardar Deporte', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}