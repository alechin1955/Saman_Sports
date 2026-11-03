import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_sizes.dart';
import '../models/sport_model.dart';
import '../models/entrenador_model.dart';
import '../repositories/sport_repository.dart';
import '../repositories/entrenador_repository.dart';
import '../controllers/sport_controller.dart';
import '../controllers/entrenador_controller.dart';
import 'new_sport_view.dart';
import 'edit_sport_dialog.dart';
import 'new_entrenador_view.dart';
import 'edit_entrenador_dialog.dart';

class AdminDashboardView extends StatefulWidget {
  final dynamic auth;
  const AdminDashboardView({super.key, this.auth});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedIndex = 0;
  final SportController _sportController = SportController();
  final EntrenadorController _entrenadorController = EntrenadorController();

  // --- MÉTODOS DE DEPORTES ---
  Future<void> _abrirEditarDeporte(SportModel sport) async {
    final actualizado = await showDialog<bool>(
      context: context,
      builder: (context) => EditSportDialog(sport: sport),
    );
    if (actualizado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deporte actualizado'), backgroundColor: AppColors.success));
      setState(() {});
    }
  }

  Future<void> _confirmarEliminacion(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      final exito = await _sportController.deleteSport(id);
      if (exito && mounted) setState(() {});
    }
  }

  // --- MÉTODOS DE ENTRENADORES ---
  Future<void> _abrirEditarEntrenador(EntrenadorModel entrenador) async {
    final actualizado = await showDialog<bool>(
      context: context,
      builder: (context) => EditEntrenadorDialog(entrenador: entrenador),
    );
    if (actualizado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrenador actualizado'), backgroundColor: AppColors.success));
      setState(() {});
    }
  }

  Future<void> _confirmarEliminacionEntrenador(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Eliminar al entrenador "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      final exito = await _entrenadorController.deleteEntrenador(id);
      if (exito && mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.panelAdmin),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            backgroundColor: AppColors.surface,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text(AppStrings.dashboard)),
              NavigationRailDestination(icon: Icon(Icons.sports_soccer), label: Text(AppStrings.deportes)),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text(AppStrings.entrenadores)),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.space24),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardOverview();
      case 1: return _buildSportsManagement();
      case 2: return _buildEntrenadoresManagement();
      default: return const Center(child: Text('Error de navegación'));
    }
  }

  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.resumenGeneral, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: AppSizes.space16),
          Wrap(
            spacing: AppSizes.space16,
            runSpacing: AppSizes.space16,
            children: [
              _buildStatCard(AppStrings.totalDeportes, '8', Icons.sports, AppColors.primary),
              _buildStatCard(AppStrings.totalEntrenadores, '12', Icons.badge, AppColors.navy),
              _buildStatCard(AppStrings.totalEstudiantes, '340', Icons.school, AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
              const SizedBox(width: AppSizes.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportsManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.deportes, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NewSportView())).then((_) => setState(() {})),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.nuevoDeporte),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        Expanded(
          child: FutureBuilder<List<SportModel>>(
            future: SportRepository().getSports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay deportes registrados aún.', style: TextStyle(color: AppColors.textSecondary)));
              }
              final deportes = snapshot.data!;
              return ListView.builder(
                itemCount: deportes.length,
                itemBuilder: (context, index) {
                  final deporte = deportes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.space12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.sports, color: AppColors.primary)),
                      title: Text(deporte.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Horario: ${deporte.horario} | Cupos: ${deporte.cuposDisponibles}/${deporte.cuposTotales}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: AppColors.navy), onPressed: () => _abrirEditarDeporte(deporte)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { if (deporte.id != null) _confirmarEliminacion(deporte.id!, deporte.nombre); }),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntrenadoresManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Entrenadores', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NewEntrenadorView())).then((_) => setState(() {})),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Entrenador'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        Expanded(
          child: FutureBuilder<List<EntrenadorModel>>(
            future: EntrenadorRepository().getEntrenadores(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay entrenadores registrados aún.', style: TextStyle(color: AppColors.textSecondary)));
              }
              final entrenadores = snapshot.data!;
              return ListView.builder(
                itemCount: entrenadores.length,
                itemBuilder: (context, index) {
                  final entrenador = entrenadores[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.space12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.navy.withOpacity(0.1), child: const Icon(Icons.person, color: AppColors.navy)),
                      title: Text('${entrenador.nombre} - ${entrenador.especialidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('C.I: ${entrenador.cedula} | ${entrenador.correo} | ${entrenador.anosExperiencia} años exp.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.navy),
                            onPressed: () => _abrirEditarEntrenador(entrenador),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () { if (entrenador.id != null) _confirmarEliminacionEntrenador(entrenador.id!, entrenador.nombre); },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}