import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/home/widgets/cta_section.dart';
import 'package:saman_sports/views/home/widgets/deportes_section.dart';
import 'package:saman_sports/views/home/widgets/entrenadores_section.dart';
import 'package:saman_sports/views/home/widgets/footer_publico.dart';
import 'package:saman_sports/views/home/widgets/hero_section.dart';
import 'package:saman_sports/views/home/widgets/que_es_section.dart';
import 'package:saman_sports/views/home/widgets/resenas_section.dart';
import 'package:saman_sports/views/widgets/public_header.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.controller});

  final HomeController controller;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _scroll = ScrollController();
  final _inicio = GlobalKey();
  final _deportes = GlobalKey();
  final _entrenadores = GlobalKey();
  final _resenas = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.iniciar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final header = PublicHeader(
      linkActivo: AppStrings.inicio,
      onIniciarSesion: () => Navigator.pushNamed(context, AppRoutes.login),
      onRegistrarse: () => Navigator.pushNamed(context, AppRoutes.registro),
      onLink: _irA,
    );
    return Scaffold(
      appBar: header,
      drawer: header.buildDrawer(context),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          return SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                HeroSection(
                  key: _inicio,
                  onExplorar: () => _irA(AppStrings.deportes),
                  onRegistrarme: () => Navigator.pushNamed(context, AppRoutes.registro),
                  disciplinas: controller.totalDisciplinas,
                  entrenadores: controller.totalEntrenadores,
                  valoracion: controller.promedioEstrellas.toStringAsFixed(1),
                  resenas: controller.totalResenas,
                ),
                const QueEsSection(),
                DeportesSection(key: _deportes, controller: controller, onDetalles: () => _proximamente(context)),
                EntrenadoresSection(key: _entrenadores, controller: controller),
                ResenasSection(key: _resenas, controller: controller),
                CtaSection(onRegistrarme: () => Navigator.pushNamed(context, AppRoutes.registro)),
                FooterPublico(onLink: _irA),
              ],
            ),
          );
        },
      ),
    );
  }

  void _irA(String link) {
    final key = switch (link) {
      AppStrings.deportes => _deportes,
      AppStrings.entrenadores => _entrenadores,
      AppStrings.resenas => _resenas,
      _ => _inicio,
    };
    final destino = key.currentContext;
    if (destino != null) {
      Scrollable.ensureVisible(destino, duration: const Duration(milliseconds: 300));
    }
  }

  void _proximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.proximamente)),
    );
  }
}
