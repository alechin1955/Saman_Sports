# Pruebas de reglas de Firestore

Validan `firestore.rules` contra el emulador local. No despliegan nada y no leen ni escriben el proyecto real `saman-sports`. El proyecto de prueba es `demo-saman`: el prefijo `demo-` impide que la CLI se conecte a Firebase real.

## Requisitos

- Node.js 18 o superior (`node --version`)
- Java 21 o superior (`java -version`). El emulador de Firestore lo necesita.
- Firebase CLI 13 o superior. En PowerShell, si `firebase` está bloqueado por la política de scripts, usa `firebase.cmd --version`.

Si falta alguno:

```powershell
winget install OpenJS.NodeJS.LTS
winget install Oracle.JDK.21
npm install -g firebase-tools
```

## Instalar

Desde la raíz del repositorio:

```powershell
npm --prefix test_rules install
```

## Correr

Desde la raíz del repositorio, con el emulador y sin deploy:

```powershell
firebase.cmd emulators:exec --only firestore --project demo-saman "npm --prefix test_rules test"
```

`emulators:exec` levanta Firestore, corre Mocha y apaga el emulador al terminar. Los datos los crea cada prueba con `withSecurityRulesDisabled`. No uses cuentas ni documentos reales.

## Qué cubre

- Sin sesión: `usuarios` denegado; deportes, entrenadores y canchas activos permitidos; reseñas visibles permitidas; inactivos y listados sin filtro denegados.
- Estudiante: lee solo su usuario; edita nombre y teléfono; no cambia `rol`, `estado` ni `solvente`; el registro solo acepta `rol == estudiante`; crea reseñas con su `autorUid`; no verifica pagos; lee sus notificaciones y solo cambia `leida`. Solo se inscribe si está solvente, el deporte está activo y la misma escritura mueve `inscritos` en ±1. Lee asistencia solo con inscripción pendiente o confirmada.
- Usuario inactivo: puede leer su propio `usuarios/{uid}` para que el login vea `estado`. Cualquier otra lectura privada queda denegada.
- Entrenador: actualiza solo `descripcion` de su deporte; no toca el deporte de otro ni `cupos` o `entrenadorUid`; guarda asistencia de su disciplina; lee reservas activas por cancha; crea su ticket y no lo responde.
- Admin: cambia `estado` y `solvente`, crea deportes, cambia `visible` de una reseña y, de forma temporal, actualiza pagos.
- `configuracion/pagos`: lectura con sesión activa; escritura solo del admin.
- Ruta no declarada y la colección raíz `asistencias`: denegadas. La asistencia real vive en `deportes/{id}/asistencias`.
- Cada consulta de `lib/FirebaseServices.dart` se prueba con el mismo `where` y el rol que la usa.

## Permisos temporales

Estos cuatro huecos existen para que la app actual no falle. No cambian Dart. Hay que cerrarlos cuando exista el ajuste indicado.

1. **Pagos.** El admin activo puede actualizar `pagos`, incluido `verificado` y `estado`, para que `cambiarEstadoPago` y `registrarPagoPaypal` sigan funcionando. El estudiante y una sesión anónima no pueden actualizarlos. Quitar el `allow update: if isAdmin()` cuando exista la Cloud Function de PayPal. El comentario en `firestore.rules` es `TEMPORAL: quitar cuando exista la Cloud Function de PayPal`.
2. **Inscripciones.** Un entrenador activo puede listar `inscripciones` filtradas por `deporteId` (`getInscripcionesConfirmadas`). La regla de lista no puede comprobar que ese deporte sea suyo, así que cualquier entrenador activo puede listar las de cualquier disciplina. Para cerrarlo, guardar `entrenadorUid` en cada inscripción y consultar `.where('entrenadorUid', isEqualTo: uid)`.
3. **Usuarios.** Un entrenador activo puede hacer `get` de `usuarios` con `rol == 'estudiante'`, para mostrar el nombre del alumno. Eso también le deja leer cédula, teléfono, correo y solvencia. No puede listar todos los estudiantes ni leer admin u otros entrenadores. Para cerrarlo, copiar el nombre visible en la inscripción y dejar de llamar a `getUserData`.
4. **Canchas.** Un entrenador activo puede listar todas las canchas, activas e inactivas, y leer una cancha inactiva. Así `streamCanchasEntrenador` no falla y el `get` de la línea 586 puede mostrar "cancha inactiva". Estudiante y anónimo siguen sin ver inactivas ni listar sin filtro. Para cerrarlo, agregar `.where('activa', isEqualTo: true)` a `streamCanchasEntrenador` y tratar el permiso denegado de una cancha inactiva en el cliente, o no pedir el documento si ya se sabe que está inactiva.

No incluyas `test_rules/node_modules` en un commit.
