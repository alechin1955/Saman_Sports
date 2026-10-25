import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class DisciplinasNomina extends StatelessWidget {
  const DisciplinasNomina({super.key, required this.controller});
  final EntrenadorController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      if (c.cargando) return const Center(child: CircularProgressIndicator());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            children: [
              Text('Mis disciplinas', style: AppTextStyles.title),
              TextButton.icon(
                onPressed: c.cargandoNomina ? null : c.cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          if (c.error != null) ...[
            const SizedBox(height: 12),
            Text(
              c.error!,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => c.seleccionId == null
                    ? c.cargar()
                    : c.seleccionar(c.seleccionId!),
                child: const Text('Reintentar'),
              ),
            ),
          ],
          if (c.disciplinas.isEmpty && c.error == null)
            const _Estado(
              icono: Icons.sports_outlined,
              titulo: 'Aún no tienes disciplinas asignadas',
              mensaje: 'La coordinación deportiva debe asignarte una disciplina para consultar sus inscritos.',
            ),
          if (c.disciplinas.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final d in c.disciplinas)
                  SizedBox(
                    width: 260,
                    child: Card(
                      color: c.seleccionId == d.id
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        side: BorderSide(
                          color: c.seleccionId == d.id
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        onTap: () => c.seleccionar(d.id),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.sports,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(d.nombre, style: AppTextStyles.subtitle),
                              const SizedBox(height: 8),
                              Text(
                                d.horario.isEmpty
                                    ? 'Horario por definir'
                                    : d.horario,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${d.inscritos} inscritos · ${d.cupos} cupos',
                              ),
                              if (c.seleccionId == d.id)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Disciplina seleccionada',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Nómina de inscritos', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            const Text(
              'Estudiantes con inscripción confirmada en la disciplina seleccionada.',
            ),
            const SizedBox(height: 16),
            if (c.cargandoNomina)
              const Center(child: CircularProgressIndicator())
            else if (c.error == null) ...[
              TextField(
                key: ValueKey(c.seleccionId),
                onChanged: c.buscar,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar por nombre, carnet o correo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('${c.filtrados.length} de ${c.alumnos.length} estudiantes'),
              if (c.alumnos.isEmpty)
                const _Estado(
                  icono: Icons.groups_outlined,
                  titulo: 'Todavía no hay inscritos confirmados',
                  mensaje: 'Las inscripciones pendientes o canceladas no aparecen en esta nómina.',
                )
              else if (c.filtrados.isEmpty)
                const _Estado(
                  icono: Icons.search_off,
                  titulo: 'No encontramos coincidencias',
                  mensaje: 'Prueba con otro nombre, carnet o correo.',
                )
              else ...[
                const SizedBox(height: 12),
                for (final alumno in c.filtrados)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Icon(
                              Icons.person_outline,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alumno.nombre,
                                  style: AppTextStyles.subtitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Carnet: ${alumno.carnet.isEmpty ? 'No disponible' : alumno.carnet}',
                                ),
                                if (alumno.correo.isNotEmpty)
                                  Text(alumno.correo),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ],
      );
    },
  );
}

class _Estado extends StatelessWidget {
  const _Estado({
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });
  final IconData icono;
  final String titulo;
  final String mensaje;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(icono, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          titulo,
          style: AppTextStyles.subtitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(mensaje, textAlign: TextAlign.center),
      ],
    ),
  );
}
