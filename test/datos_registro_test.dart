import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/datos_registro.dart';

void main() {
  test('toMap recorta textos y guarda el rol estudiante', () {
    final datos = DatosRegistro(
      nombre: ' Ana ',
      apellido: ' Pérez ',
      cedula: ' V-12345678 ',
      carnet: ' 2023111012 ',
      telefono: ' 0414-1234567 ',
      correo: ' Ana@Correo.unimet.edu.ve ',
      clave: 'secreta',
    );

    final mapa = datos.toMap();

    expect(mapa['nombre'], 'Ana');
    expect(mapa['apellido'], 'Pérez');
    expect(mapa['cedula'], 'V-12345678');
    expect(mapa['correo'], 'ana@correo.unimet.edu.ve');
    expect(mapa['rol'], 'estudiante');
    expect(mapa.containsKey('clave'), isFalse);
    expect(mapa['creadoEn'], isA<String>());
  });
}
