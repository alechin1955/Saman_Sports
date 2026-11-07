import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/perfil_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class PerfilEntrenadorView extends StatefulWidget {
  const PerfilEntrenadorView({super.key, required this.auth, this.controller});

  final AuthController auth;
  final PerfilEntrenadorController? controller;

  @override
  State<PerfilEntrenadorView> createState() => _PerfilEntrenadorViewState();
}

class _PerfilEntrenadorViewState extends State<PerfilEntrenadorView> {
  late final PerfilEntrenadorController controller =
      widget.controller ?? PerfilEntrenadorController();
  late final bool _propio = widget.controller == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.cargar();
    });
  }

  @override
  void dispose() {
    if (_propio) controller.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await widget.auth.cerrarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorPerfil,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Mi perfil',
      descripcion: 'Consulta tu experiencia y los datos asociados a tu cuenta.',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.perfil == null && controller.error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null && controller.perfil == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MensajeError(texto: controller.error!),
                const SizedBox(height: AppSizes.space16),
                BotonSecundario(
                  texto: 'Reintentar',
                  onPressed: controller.cargar,
                ),
              ],
            );
          }
          return _PerfilContenido(
            perfil: controller.perfil!,
            totalEstudiantes: controller.totalEstudiantes,
            onCerrarSesion: _cerrarSesion,
          );
        },
      ),
    );
  }
}

class _PerfilContenido extends StatelessWidget {
  const _PerfilContenido({
    required this.perfil,
    required this.totalEstudiantes,
    required this.onCerrarSesion,
  });

  final PerfilEntrenador perfil;
  final int totalEstudiantes;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cabecera = _TarjetaPerfil(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: perfil.fotoUrl == null
                        ? null
                        : NetworkImage(perfil.fotoUrl!),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: perfil.fotoUrl == null
                        ? Text(
                            perfil.iniciales,
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSizes.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perfil.nombreCompleto, style: AppTextStyles.title),
                        Text(
                          perfil.disciplina.isEmpty
                              ? perfil.especialidad
                              : perfil.disciplina,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.space8),
                        Chip(
                          label: Text(
                            perfil.activo ? 'Cuenta activa' : 'Cuenta inactiva',
                          ),
                          side: BorderSide.none,
                          backgroundColor:
                              (perfil.activo
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space24),
              _Dato(titulo: 'Correo', valor: perfil.correo),
              _Dato(titulo: 'Teléfono', valor: perfil.telefono),
              _Dato(
                titulo: 'Experiencia',
                valor: '${perfil.anosExperiencia} años',
              ),
              _Dato(
                titulo: 'Estudiantes',
                valor: '$totalEstudiantes inscritos',
              ),
              _Dato(titulo: 'Especialidad', valor: perfil.especialidad),
              const SizedBox(height: AppSizes.space16),
              OutlinedButton.icon(
                onPressed: onCerrarSesion,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        final trayectoria = _TarjetaPerfil(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Biografía', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSizes.space8),
              Text(
                perfil.biografia.isEmpty
                    ? 'Biografía por completar.'
                    : perfil.biografia,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSizes.space24),
              Text('Certificaciones', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSizes.space8),
              if (perfil.certificaciones.isEmpty)
                Text(
                  'No hay certificaciones registradas.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final certificacion in perfil.certificaciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.space8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: AppColors.primary,
                          size: AppSizes.iconSmall,
                        ),
                        const SizedBox(width: AppSizes.space8),
                        Expanded(child: Text(certificacion)),
                      ],
                    ),
                  ),
            ],
          ),
        );
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: cabecera),
              const SizedBox(width: AppSizes.space24),
              Expanded(flex: 3, child: trayectoria),
            ],
          );
        }
        return Column(
          children: [
            cabecera,
            const SizedBox(height: AppSizes.space24),
            trayectoria,
          ],
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valor.isEmpty ? 'No registrado' : valor,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _TarjetaPerfil extends StatelessWidget {
  const _TarjetaPerfil({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
