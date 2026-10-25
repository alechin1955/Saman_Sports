import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';

/// Estructura común de los paneles por rol (estudiante, entrenador y admin).
///
/// - Escritorio (>= AppSizes.desktop): menú lateral fijo a la izquierda.
/// - Tablet y móvil: AppBar blanco con el logo y el menú dentro de un Drawer.
///
/// Cada pantalla de un panel devuelve un PanelLayout y solo define su
/// contenido en [child]; nunca dibuja su propio menú.
class PanelLayout extends StatelessWidget {
  const PanelLayout({
    super.key,
    required this.auth,
    required this.opciones,
    required this.rutaActiva,
    required this.subtituloPanel,
    required this.titulo,
    required this.descripcion,
    required this.child,
  });

  final AuthController auth;
  final List<OpcionPanel> opciones;
  final String rutaActiva;
  final String subtituloPanel;
  final String titulo;
  final String descripcion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final escritorio = constraints.maxWidth >= AppSizes.desktop;
        final movil = constraints.maxWidth < AppSizes.mobile;

        final contenido = _ContenidoPanel(
          titulo: titulo,
          descripcion: descripcion,
          movil: movil,
          child: child,
        );

        if (escritorio) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppSizes.panelMenuAncho,
                  child: _MenuPanel(
                    auth: auth,
                    opciones: opciones,
                    rutaActiva: rutaActiva,
                    subtitulo: subtituloPanel,
                    enDrawer: false,
                  ),
                ),
                Expanded(child: contenido),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: AppColors.surface,
            foregroundColor: AppColors.navy,
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: AppColors.border)),
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AppLogo(size: AppSizes.logoHeader, mostrarTexto: true),
            ),
          ),
          drawer: Drawer(
            backgroundColor: AppColors.surface,
            width: AppSizes.panelMenuAncho,
            child: SafeArea(
              child: _MenuPanel(
                auth: auth,
                opciones: opciones,
                rutaActiva: rutaActiva,
                subtitulo: subtituloPanel,
                enDrawer: true,
              ),
            ),
          ),
          body: contenido,
        );
      },
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.auth,
    required this.opciones,
    required this.rutaActiva,
    required this.subtitulo,
    required this.enDrawer,
  });

  final AuthController auth;
  final List<OpcionPanel> opciones;
  final String rutaActiva;
  final String subtitulo;
  final bool enDrawer;

  @override
  Widget build(BuildContext context) {
    // Material (y no Container con color) para que se vea el fondo
    // naranja suave del ítem activo de los ListTile.
    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: enDrawer
              ? null
              : const Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppLogo(
                      size: AppSizes.logoHeader,
                      mostrarTexto: true,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space8),
                  Text(
                    subtitulo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.space12),
                children: [
                  for (final opcion in opciones)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.space4),
                      child: _ItemMenu(
                        opcion: opcion,
                        activa: opcion.ruta == rutaActiva,
                        enDrawer: enDrawer,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSizes.space12),
              child: _BotonCerrarSesion(auth: auth),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.opcion,
    required this.activa,
    required this.enDrawer,
  });

  final OpcionPanel opcion;
  final bool activa;
  final bool enDrawer;

  @override
  Widget build(BuildContext context) {
    final color = activa ? AppColors.primary : AppColors.navy;
    return ListTile(
      dense: true,
      selected: activa,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
      hoverColor: AppColors.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      leading: Icon(
        opcion.icono,
        color: activa ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        opcion.texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.label.copyWith(color: color),
      ),
      onTap: () {
        if (activa) {
          if (enDrawer) Navigator.pop(context);
          return;
        }
        Navigator.pushReplacementNamed(context, opcion.ruta);
      },
    );
  }
}

class _BotonCerrarSesion extends StatelessWidget {
  const _BotonCerrarSesion({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      hoverColor: AppColors.error.withValues(alpha: 0.06),
      leading: const Icon(Icons.logout, color: AppColors.error),
      title: Text(
        AppStrings.cerrarSesion,
        style: AppTextStyles.label.copyWith(color: AppColors.error),
      ),
      onTap: () async {
        await auth.cerrarSesion();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );
      },
    );
  }
}

class _ContenidoPanel extends StatelessWidget {
  const _ContenidoPanel({
    required this.titulo,
    required this.descripcion,
    required this.movil,
    required this.child,
  });

  final String titulo;
  final String descripcion;
  final bool movil;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(movil ? AppSizes.space16 : AppSizes.space24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.panelContenidoMax,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: movil ? AppTextStyles.title : AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSizes.space4),
              Text(
                descripcion,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.space24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
