import 'package:flutter/material.dart';
import 'package:saman_sports/core/routes/app_routes.dart';

class SamanSportsApp extends StatelessWidget {
  const SamanSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saman Sports',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes(),
    );
  }
}
