import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/repositories/admin/admin_transaccion_repository.dart';
import 'package:saman_sports/repositories/admin/resolutor_nombres_repository.dart';
import 'package:saman_sports/views/admin/transacciones_admin_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('transacciones no se desborda a 1024 px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final panel = AdminTransaccionController(repository: _Historial());
    addTearDown(panel.dispose);
    panel.iniciar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransaccionesAdminView(transacciones: panel),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.adminRol), findsWidgets);
    expect(find.text(AppStrings.adminModulo), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tabla no muestra el id de una transacción vieja', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const token = 'PAGO1234567890123456';
    final panel = AdminTransaccionController(
      repository: _Historial(descripcion: 'Verificó el pago $token'),
      resolutor: _Resolutor({token: 'del período 2026-1'}),
    );
    addTearDown(panel.dispose);
    panel.iniciar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TransaccionesAdminView(transacciones: panel)),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(Duration.zero);
    }

    expect(find.textContaining(token), findsNothing);
    expect(find.textContaining('del período 2026-1'), findsOneWidget);
  });
}

class _Resolutor implements ResolutorNombresAdmin {
  _Resolutor(this.pagos);

  final Map<String, String> pagos;

  @override
  Future<String?> nombre(String coleccion, String id) async {
    if (coleccion != 'pagos') return null;
    return pagos[id];
  }
}

class _Historial implements AdminTransaccionRepository {
  _Historial({this.descripcion = 'Creó un evento'});

  final String descripcion;

  @override
  Stream<List<Transaccion>> transacciones() => Stream.value([
    Transaccion(
      id: 't1',
      fecha: DateTime(2026, 11, 8, 10, 30),
      usuarioUid: 'admin',
      usuarioNombre: 'Admin',
      rol: 'administrador',
      accion: 'crear',
      modulo: 'pagos',
      descripcion: descripcion,
    ),
  ]);
}
