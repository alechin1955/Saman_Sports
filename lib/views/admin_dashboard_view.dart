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
      backgroundColor: const Color(0xFFF8F9FA),
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
            extended: true,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text(AppStrings.dashboard)),
              NavigationRailDestination(icon: Icon(Icons.sports_soccer), label: Text(AppStrings.deportes)),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text(AppStrings.entrenadores)),
              NavigationRailDestination(icon: Icon(Icons.school), label: Text('Estudiantes')),
              NavigationRailDestination(icon: Icon(Icons.sports_basketball), label: Text('Partidos')),
              NavigationRailDestination(icon: Icon(Icons.support_agent), label: Text('Soporte')),
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
      case 3: return _buildEstudiantesManagement();
      case 4: return _buildPartidosManagement();
      case 5: return _buildSoporteManagement();
      default: return const Center(child: Text('Error de navegación'));
    }
  }

  // 1. DASHBOARD OVERVIEW CON RESUMEN GENERAL
  Widget _buildDashboardOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1D2D44))),
        const Text('Universidad Metropolitana - Samán Deportivo', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 24),
        Expanded(child: _buildSummaryCards()),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _crearTarjeta('Estudiantes Registrados', '13', Icons.school),
        _crearTarjeta('Deportes Activos', '6', Icons.sports_soccer),
        _crearTarjeta('Entrenadores', '6', Icons.person),
        _crearTarjeta('Inscripciones Pendientes', '1', Icons.assignment_late),
      ],
    );
  }

  Widget _crearTarjeta(String titulo, String valor, IconData icono) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Icon(icono, color: const Color(0xFFE85D04), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2A9D8F))),
          ],
        ),
      ),
    );
  }

  // 2. GESTIÓN DE DEPORTES
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

  // 3. GESTIÓN DE ENTRENADORES
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
                      title: Text('${entrenador.nombre}\n${entrenador.especialidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('C.I: ${entrenador.cedula} | ${entrenador.correo} | ${entrenador.anosExperiencia} años exp.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: AppColors.navy), onPressed: () => _abrirEditarEntrenador(entrenador)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { if (entrenador.id != null) _confirmarEliminacionEntrenador(entrenador.id!, entrenador.nombre); }),
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

  // 4. GESTIÓN DE ESTUDIANTES
  Widget _buildEstudiantesManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gestión de Estudiantes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D2D44))),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE85D04), child: Text('VM', style: TextStyle(color: Colors.white))),
                  title: const Text('Valeria Martínez'),
                  subtitle: const Text('valeria.martinez@correo.unimet.edu.ve'),
                  trailing: SizedBox(
                    width: 250,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _construirIndicadorSolvencia(true),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE85D04), foregroundColor: Colors.white),
                          onPressed: () {},
                          child: const Text('Ver perfil'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirIndicadorSolvencia(bool esSolvente) {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: esSolvente ? const Color(0xFF2A9D8F) : const Color(0xFFE63946)),
        const SizedBox(width: 8),
        Text(
          esSolvente ? 'Solvente' : 'Pendiente',
          style: TextStyle(color: esSolvente ? const Color(0xFF2A9D8F) : const Color(0xFFE63946), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 5. SOLICITUDES DE PARTIDOS
  Widget _buildPartidosManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Solicitudes de Partidos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D2D44))),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_basketball, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay solicitudes pendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Las propuestas enviadas por los entrenadores aparecerán aquí.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), foregroundColor: Colors.white),
                    onPressed: () {},
                    child: const Text('Aprobar Solicitud'),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 6. SOPORTE TÉCNICO
  Widget _buildSoporteManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Soporte Técnico', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D2D44))),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: [
              Card(
                child: ListTile(
                  title: const Text('Problema con pago (SUP-001)'),
                  subtitle: const Text('Valeria Martínez • 2024-11-20'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE85D04),
                      side: const BorderSide(color: Color(0xFFE85D04)),
                    ),
                    onPressed: () {},
                    child: const Text('Marcar Solventado'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}