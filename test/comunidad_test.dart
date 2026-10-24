import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/comunidad_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/constants/datos_ejemplo.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/views/estudiante/comunidad_view.dart';

const _perfil = <String, dynamic>{'nombre': 'María', 'apellido': 'González'};

final _miResena = <String, dynamic>{
  'id': 'r1',
  'autorUid': 'abc',
  'autorNombre': 'María G.',
  'disciplina': 'Tenis',
  'deporteId': 'ej-tenis',
  'estrellas': 4,
  'comentario': 'Las clases son muy ordenadas.',
  'fecha': DateTime(2026, 10, 20),
};

/// Guarda lo que el controlador le pide a la fachada.
class _FachadaFalsa {
  Map<String, dynamic>? creada;
  String? actualizadaId;
  String? eliminadaId;
  bool falla = false;

  AuthResponse _respuesta() => falla
      ? AuthResponse(isSuccess: false, errorMessage: 'No tienes permiso.')
      : AuthResponse(isSuccess: true);
}

ComunidadController _controlador(
  _FachadaFalsa fachada, {
  List<Map<String, dynamic>> resenas = const [],
  String? uid = 'abc',
}) {
  return ComunidadController(
    uidActual: () => uid,
    leerPerfil: (uid) async => _perfil,
    misResenasOrigen: (uid) => Stream.value(resenas),
    deportesOrigen: () => Stream.value(const []),
    crear: (data) async {
      fachada.creada = data;
      return fachada._respuesta();
    },
    actualizar: (id, data) async {
      fachada.actualizadaId = id;
      return fachada._respuesta();
    },
    eliminar: (id) async {
      fachada.eliminadaId = id;
      return fachada._respuesta();
    },
  );
}

void main() {
  group('ComunidadController', () {
    test('sin sesión muestra el mensaje de sesión expirada', () async {
      final c = _controlador(_FachadaFalsa(), uid: null);
      await c.iniciar();
      expect(c.error, AppStrings.sesionNoIniciada);
      c.dispose();
    });

    test(
      'carga mis reseñas, los deportes y el nombre corto del autor',
      () async {
        final c = _controlador(_FachadaFalsa(), resenas: [_miResena]);
        await c.iniciar();
        await Future<void>.delayed(Duration.zero);

        expect(c.cargando, isFalse);
        expect(c.misResenas.single.comentario, 'Las clases son muy ordenadas.');
        expect(c.deportes.length, DatosEjemplo.deportes.length);
        expect(c.autorNombre, 'María G.');
        c.dispose();
      },
    );

    test('valida disciplina, estrellas y largo del comentario', () async {
      final fachada = _FachadaFalsa();
      final c = _controlador(fachada);
      await c.iniciar();
      final tenis = DatosEjemplo.deportes[2];

      expect(
        await c.publicar(
          deporte: null,
          estrellas: 5,
          comentario: 'Muy buenas clases',
        ),
        isFalse,
      );
      expect(c.errorFormulario, AppStrings.elegirDisciplinaError);

      await c.publicar(
        deporte: tenis,
        estrellas: 0,
        comentario: 'Muy buenas clases',
      );
      expect(c.errorFormulario, AppStrings.elegirEstrellasError);

      await c.publicar(deporte: tenis, estrellas: 5, comentario: 'Corto');
      expect(c.errorFormulario, AppStrings.comentarioCorto);

      expect(fachada.creada, isNull);
      c.dispose();
    });

    test('publica la reseña con los datos correctos', () async {
      final fachada = _FachadaFalsa();
      final c = _controlador(fachada);
      await c.iniciar();

      final ok = await c.publicar(
        deporte: DatosEjemplo.deportes[2],
        estrellas: 5,
        comentario: '  Muy buenas clases de tenis  ',
      );

      expect(ok, isTrue);
      expect(fachada.creada, {
        'autorUid': 'abc',
        'autorNombre': 'María G.',
        'disciplina': 'Tenis',
        'deporteId': 'ej-tenis',
        'estrellas': 5,
        'comentario': 'Muy buenas clases de tenis',
      });
      c.dispose();
    });

    test('edita y elimina usando el id de la reseña', () async {
      final fachada = _FachadaFalsa();
      final c = _controlador(fachada);
      final resena = Resena.fromMap(_miResena);

      expect(
        await c.editar(resena, estrellas: 3, comentario: 'Ahora es regular.'),
        isTrue,
      );
      expect(fachada.actualizadaId, 'r1');
      expect(await c.eliminar(resena), isTrue);
      expect(fachada.eliminadaId, 'r1');
      c.dispose();
    });

    test('si la fachada falla muestra su mensaje', () async {
      final fachada = _FachadaFalsa()..falla = true;
      final c = _controlador(fachada);

      expect(await c.eliminar(Resena.fromMap(_miResena)), isFalse);
      expect(c.errorFormulario, 'No tienes permiso.');
      c.dispose();
    });
  });

  group('ComunidadView', () {
    Widget pantalla(ComunidadController controller) {
      return MaterialApp(
        home: ComunidadView(auth: AuthController(), controller: controller),
      );
    }

    Future<void> tocar(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> cerrarAviso(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

    for (final tamano in tamanos) {
      testWidgets('sin reseñas muestra el formulario y el estado vacío en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(_controlador(_FachadaFalsa())));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.escribeResena), findsOneWidget);
        expect(find.text(AppStrings.sinMisResenas), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('publica una reseña desde el formulario', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final fachada = _FachadaFalsa();
      await tester.pumpWidget(pantalla(_controlador(fachada)));
      await tester.pumpAndSettle();

      await tocar(tester, find.text('Tenis'));
      await tocar(tester, find.byIcon(Icons.star_border).at(4));
      await tester.enterText(
        find.byType(TextField),
        'Muy buenas clases de tenis',
      );
      await tocar(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.publicarResena),
      );

      expect(fachada.creada?['disciplina'], 'Tenis');
      expect(fachada.creada?['estrellas'], 5);
      expect(find.text(AppStrings.resenaPublicada), findsOneWidget);
      await cerrarAviso(tester);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('eliminar pide confirmación y luego borra', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final fachada = _FachadaFalsa();
      await tester.pumpWidget(
        pantalla(_controlador(fachada, resenas: [_miResena])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Las clases son muy ordenadas.'), findsOneWidget);
      await tocar(tester, find.text(AppStrings.eliminar));
      expect(find.text(AppStrings.confirmarEliminarResena), findsOneWidget);

      await tocar(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.eliminar),
      );
      expect(fachada.eliminadaId, 'r1');
      expect(find.text(AppStrings.resenaEliminada), findsOneWidget);
      await cerrarAviso(tester);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
