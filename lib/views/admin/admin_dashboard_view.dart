import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_controladores.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/admin/deportes_admin_view.dart';
import 'package:saman_sports/views/admin/entrenadores_admin_view.dart';
import 'package:saman_sports/views/admin/estudiantes_admin_view.dart';
import 'package:saman_sports/views/admin/eventos_admin_view.dart';
import 'package:saman_sports/views/admin/inscripciones_admin_view.dart';
import 'package:saman_sports/views/admin/pagos_admin_view.dart';
import 'package:saman_sports/views/admin/resenas_admin_view.dart';
import 'package:saman_sports/views/admin/resumen_view.dart';
import 'package:saman_sports/views/admin/soporte_admin_view.dart';
import 'package:saman_sports/views/admin/transacciones_admin_view.dart';
import 'package:saman_sports/views/admin/widgets/admin_sidebar.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({
    super.key,
    required this.auth,
    required this.controladores,
    this.inicial = SeccionAdmin.resumen,
  });

  final AuthController auth;
  final AdminControladores controladores;
  final SeccionAdmin inicial;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late SeccionAdmin _seccion = widget.inicial;

  @override
  void initState() {
    super.initState();
    _activar(_seccion);
  }

  void _activar(SeccionAdmin seccion) {
    final panel = widget.controladores;
    switch (seccion) {
      case SeccionAdmin.resumen:
        panel.resumen.cargar();
        panel.deportes.iniciar();
        panel.transacciones.iniciar();
      case SeccionAdmin.deportes:
        panel.deportes.iniciar();
        panel.entrenadores.iniciar();
      case SeccionAdmin.entrenadores:
        panel.entrenadores.iniciar();
        panel.deportes.iniciar();
      case SeccionAdmin.estudiantes:
        panel.estudiantes.iniciar();
      case SeccionAdmin.resenas:
        panel.resenas.iniciar();
      case SeccionAdmin.pagos:
        panel.pagos.iniciar();
      case SeccionAdmin.inscripciones:
        panel.inscripciones.iniciar();
      case SeccionAdmin.eventos:
        panel.eventos.iniciar();
      case SeccionAdmin.soporte:
        panel.soporte.iniciar();
      case SeccionAdmin.transacciones:
        panel.transacciones.iniciar();
    }
  }

  void _elegir(SeccionAdmin seccion) {
    setState(() => _seccion = seccion);
    _activar(seccion);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final escritorio = constraints.maxWidth >= AppSizes.desktop;
        final contenido = _Contenido(
          seccion: _seccion,
          controladores: widget.controladores,
        );
        if (escritorio) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                AdminSidebar(
                  activa: _seccion,
                  onSeleccion: _elegir,
                  auth: widget.auth,
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
              child: AdminSidebar(
                activa: _seccion,
                onSeleccion: _elegir,
                auth: widget.auth,
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

class _Contenido extends StatelessWidget {
  const _Contenido({required this.seccion, required this.controladores});

  final SeccionAdmin seccion;
  final AdminControladores controladores;

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
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
              Text(seccion.titulo, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSizes.space8),
              Text(seccion.descripcion, style: AppTextStyles.body),
              const SizedBox(height: AppSizes.space24),
              _cuerpo(seccion, controladores),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _cuerpo(SeccionAdmin seccion, AdminControladores controladores) {
  return switch (seccion) {
    SeccionAdmin.resumen => ResumenView(
      resumen: controladores.resumen,
      deportes: controladores.deportes,
      transacciones: controladores.transacciones,
    ),
    SeccionAdmin.deportes => DeportesAdminView(
      deportes: controladores.deportes,
      entrenadores: controladores.entrenadores,
    ),
    SeccionAdmin.entrenadores => EntrenadoresAdminView(
      entrenadores: controladores.entrenadores,
      deportes: controladores.deportes,
    ),
    SeccionAdmin.estudiantes => EstudiantesAdminView(
      estudiantes: controladores.estudiantes,
    ),
    SeccionAdmin.inscripciones => InscripcionesAdminView(
      inscripciones: controladores.inscripciones,
    ),
    SeccionAdmin.pagos => PagosAdminView(pagos: controladores.pagos),
    SeccionAdmin.eventos => EventosAdminView(eventos: controladores.eventos),
    SeccionAdmin.resenas => ResenasAdminView(resenas: controladores.resenas),
    SeccionAdmin.soporte => SoporteAdminView(soporte: controladores.soporte),
    SeccionAdmin.transacciones => TransaccionesAdminView(
      transacciones: controladores.transacciones,
    ),
  };
}
