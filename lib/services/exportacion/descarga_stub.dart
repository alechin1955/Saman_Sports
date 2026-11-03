import 'package:flutter/services.dart';

Future<void> entregarCsv(String nombre, String contenido) =>
    Clipboard.setData(ClipboardData(text: contenido));
