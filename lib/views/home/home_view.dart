import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/home/widgets/hero_section.dart';
import 'package:saman_sports/views/widgets/public_header.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final header = PublicHeader(
      linkActivo: AppStrings.inicio,
      onIniciarSesion: () => Navigator.pushNamed(context, AppRoutes.login),
      onRegistrarse: () => Navigator.pushNamed(context, AppRoutes.registro),
      onLink: (link) => _alElegirLink(context, link),
    );

    return Scaffold(
      appBar: header,
      drawer: header.buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: HeroSection(
                onExplorar: () => _proximamente(context),
                onRegistrarme: () =>
                    Navigator.pushNamed(context, AppRoutes.registro),
              ),
            ),
          );
        },
      ),
    );
  }

  void _alElegirLink(BuildContext context, String link) {
    if (link == AppStrings.inicio) {
      return;
    }
    _proximamente(context);
  }

  void _proximamente(BuildContext context) {
    // TODO: pantallas de otros compañeros.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.proximamente)),
    );
  }
}
