import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'views/admin_dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SamanDeportivoAdminApp());
}

class SamanDeportivoAdminApp extends StatelessWidget {
  const SamanDeportivoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samán Deportivo - Administrador',
      debugShowCheckedModeBanner: false,
      theme: UnimetTheme.themeData,
      home: const AdminDashboardView(),
    );
  }
}
