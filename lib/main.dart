import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SamanSportsApp());
}
