import 'dart:convert';

import 'package:web/web.dart' as web;

Future<void> entregarCsv(String nombre, String contenido) async {
  final enlace = web.HTMLAnchorElement()
    ..href = Uri.dataFromString(
      contenido,
      mimeType: 'text/csv',
      encoding: utf8,
    ).toString()
    ..download = nombre;
  web.document.body!.append(enlace);
  enlace.click();
  enlace.remove();
}
