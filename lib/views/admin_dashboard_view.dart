import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';
import '../models/sport_model.dart';
// Importación del Design System Institucional UNIMET centralizado
import '../config/theme.dart'; 

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _controller = AdminController();

  void _openSportFormDialog({SportModel? sport}) {
    final isEditing = sport != null;
    final nameCtrl = TextEditingController(text: sport?.name ?? '');
    final capCtrl = TextEditingController(text: sport != null ? sport.maxCapacity.toString() : '');
    final scheduleCtrl = TextEditingController(text: sport?.schedule ?? '');
    final coachCtrl = TextEditingController(text: sport?.assignedCoach ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEditing ? 'Editar Disciplina' : 'Alta de Disciplina Deportiva',
          style: const TextStyle(color: UnimetTheme.secondaryNavy, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Disciplina', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cupo Máximo', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: scheduleCtrl, decoration: const InputDecoration(labelText: 'Horario (Ej. L/M/V 10:00 - 12:00)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: coachCtrl, decoration: const InputDecoration(labelText: 'Entrenador Asignado', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: UnimetTheme.primaryOrange),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final cap = int.tryParse(capCtrl.text.trim()) ?? 0;
              final schedule = scheduleCtrl.text.trim();
              final coach = coachCtrl.text.trim();
              
              if (name.isNotEmpty) {
                if (isEditing) {
                  await _controller.updateSport(sport.id, name, cap, schedule, coach);
                } else {
                  await _controller.createSport(name, cap, schedule, coach);
                }
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _determineStatusColor(int enrolled, int capacity) {
    if (capacity == 0) return UnimetTheme.statusFull;
    final ratio = enrolled / capacity;
    if (ratio >= 1.0) return UnimetTheme.statusFull;
    if (ratio >= 0.8) return UnimetTheme.statusLimited;
    return UnimetTheme.statusAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnimetTheme.background,
      appBar: AppBar(
        backgroundColor: UnimetTheme.secondaryNavy,
        title: const Text('Samán Deportivo — Administración', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<SportModel>>(
        stream: _controller.sportsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sports = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sports.length,
            itemBuilder: (context, index) {
              final sport = sports[index];
              final statusColor = _determineStatusColor(sport.enrolledCount, sport.maxCapacity);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: const Icon(Icons.sports, color: Colors.white),
                  ),
                  title: Text(sport.name, style: const TextStyle(fontWeight: FontWeight.bold, color: UnimetTheme.secondaryNavy)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entrenador: ${sport.assignedCoach}'),
                      Text('Horario: ${sport.schedule}'),
                      Text('Cupos: ${sport.enrolledCount} / ${sport.maxCapacity}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: UnimetTheme.primaryOrange), onPressed: () => _openSportFormDialog(sport: sport)),
                      IconButton(icon: const Icon(Icons.delete, color: UnimetTheme.statusFull), onPressed: () => _controller.deleteSport(sport.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UnimetTheme.primaryOrange,
        onPressed: () => _openSportFormDialog(),
        label: const Text('Registrar Deporte', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}