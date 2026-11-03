import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_sizes.dart';
import '../controllers/entrenador_controller.dart';

class NewEntrenadorView extends StatefulWidget {
  const NewEntrenadorView({super.key});

  @override
  State<NewEntrenadorView> createState() => _NewEntrenadorViewState();
}

class _NewEntrenadorViewState extends State<NewEntrenadorView> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _especialidadController = TextEditingController();
  final _experienciaController = TextEditingController();
  
  final EntrenadorController _controller = EntrenadorController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _especialidadController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  Future<void> _guardarEntrenador() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final exito = await _controller.createEntrenador(
      cedula: _cedulaController.text.trim(),
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      especialidad: _especialidadController.text.trim(),
      anosExperiencia: int.parse(_experienciaController.text.trim()),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrenador registrado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Intenta de nuevo.'),
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
        title: const Text('Nuevo Entrenador'),
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
                        controller: _cedulaController,
                        decoration: const InputDecoration(labelText: 'Cédula', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSizes.space16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSizes.space16),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          if (!val.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.space16),
                      TextFormField(
                        controller: _especialidadController,
                        decoration: const InputDecoration(labelText: 'Especialidad (ej. Fútbol, Tenis)', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSizes.space16),
                      TextFormField(
                        controller: _experienciaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Años de Experiencia', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          if (int.tryParse(val) == null) return 'Debe ser un número';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.space24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.space16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _guardarEntrenador,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Guardar Entrenador', style: TextStyle(fontSize: 16)),
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