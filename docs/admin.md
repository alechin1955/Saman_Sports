# Módulo de administrador

Ruta `/admin`. Solo entra un usuario con `usuarios/{uid}.rol == 'administrador'`, por `GuardiaRol`. La sesión restaurada también cae en este panel.

Flujo: vista → controlador `Admin*` → repositorio `admin/` → `FirebaseServices` (sección `ADMINISTRADOR`) → Firebase. Las vistas no importan Firebase ni crean repositorios.

No hay botón de eliminar entrenadores ni deportes. Desactivar los oculta (`activo: false` o `estado: 'inactivo'`).

## Qué hace cada sección

| Sección | Qué hace |
| --- | --- |
| Resumen | Conteos de estudiantes, entrenadores activos, deportes, canchas, inscripciones, pagos, reseñas ocultas, tickets abiertos, eventos aprobados e ingresos. Muestra ocupación por deporte y las últimas acciones. |
| Deportes | Alta y edición de canchas y deportes. El deporte exige cancha y al menos una franja. Asigna entrenador. Desactivar un deporte con inscritos, o una cancha con reservas activas, se bloquea. |
| Entrenadores | Crea la cuenta (`@unimet.edu.ve`) sin cerrar la sesión del admin. Edita perfil. Desactivar no borra la cuenta y se bloquea si todavía tiene un deporte activo. |
| Estudiantes | Filtros Todos, Activos, Inactivos, Solventes y Pendientes. Búsqueda por nombre o carnet. Activa o desactiva. La cédula solo sale en "Ver detalle", no en la tabla. |
| Inscripciones | Confirma, cancela o reactiva. Cancelar libera cupo. Reactivar a pendiente o confirmar vuelve a ocuparlo y falla si no hay cupo. |
| Pagos | Guarda período, fecha de inicio, fecha de corte y monto en `configuracion/pagos`. Lista pagos. "Verificar con PayPal" hoy es simulado. "Aplicar corte" solo se habilita cuando ya pasó la fecha de corte: marca no solventes y crea notificaciones. |
| Eventos | Alta de partido o evento en una fecha concreta. Aprueba, rechaza o cancela. La reserva de la cancha sigue la misma regla de choque. |
| Reseñas | Muestra todas, visibles u ocultas. El interruptor solo cambia `visible`. |
| Transacciones | Historial de las últimas 200 acciones, filtrable por fecha, módulo y rol. No se editan ni se borran. |
| Soporte | Lista tickets abiertos o resueltos. "Solventar" guarda respuesta, `estado: resuelto` y `resueltoEn`. Si no hay tickets, el texto es "No hay tickets de soporte". |

## Modelo de datos

Colecciones nuevas o ampliadas por este módulo. Los nombres de campo de main-2 no se renombraron.

### canchas/{id}

`nombre`, `ubicacion`, `descripcion`, `activa`, `version` (entero; el cliente no lo manda en `toMap`, el servidor lo incrementa), `creadoEn`.

`version` es el candado de concurrencia. No es un dato de pantalla.

### reservas/{id}

`canchaId`, `canchaNombre`, `dia` (1 lunes … 7 domingo), `horaInicio`, `horaFin` (minutos desde medianoche, fin exclusivo), `fecha` (texto `aaaa-mm-dd` o ausente), `tipo` (`deporte` | `evento`), `refId`, `refNombre`, `activa`, `creadoEn`.

Una reserva de deporte no lleva fecha: se repite ese día de la semana. Una de evento lleva fecha y también el día de esa fecha.

### deportes/{id}

Además de los campos de main-2 (`nombre`, `descripcion`, `icono`, `horario`, `cupos`, `inscritos`, `entrenadorNombre`, `entrenadorUid`, `activo`):

- `canchaId`, `canchaNombre`
- `horarios`: lista de `{dia, horaInicio, horaFin}`
- `horario`: texto legible armado con esas franjas, para Home y Explorar

`entrenadorUid` sigue siendo el uid de Auth. El panel del entrenador busca por ese campo.

### eventos/{id}

`titulo`, `tipo` (`partido` | `evento`), `deporteId`, `deporteNombre`, `canchaId`, `canchaNombre`, `fecha` (`aaaa-mm-dd`), `horaInicio`, `horaFin`, `descripcion`, `estado` (`pendiente` | `aprobado` | `rechazado` | `cancelado`), `creadoPorUid`, `creadoEn`.

### tickets/{id}

`asunto`, `categoria`, `descripcion`, `autorUid`, `autorNombre`, `autorRol`, `estado` (`abierto` | `resuelto`), `respuesta`, `fecha`, `resueltoEn`.

### transacciones/{id}

`fecha`, `usuarioUid`, `usuarioNombre`, `rol`, `accion`, `modulo`, `descripcion`. El listado pide las últimas 200, ordenadas por `fecha` descendente.

### notificaciones/{id}

`destinatarioUid`, `tipo` (`pago_pendiente`), `titulo`, `mensaje`, `periodo`, `leida`, `fecha`. El id de un aviso de corte es `pago-{periodo}-{uid}` para no duplicarlo.

### configuracion/pagos

Documento fijo, no colección suelta: `periodo`, `fechaInicio`, `fechaCorte`, `monto`.

### pagos/{id}

Campos de main-2 más `paypalOrderId`, `fechaPago`, `verificado`, `verificadoPor`, `verificadoEn`. Hoy `verificadoPor` vale `simulado` cuando lo escribe el panel.

### usuarios y entrenadores

`usuarios/{uid}` sigue siendo privado: `cedula`, `telefono`, `correo`, `rol`, `estado`, `solvente`. `entrenadores/{uid}` es público y no copia cédula ni teléfono. Crear un entrenador escribe los dos documentos en un batch. Si el batch falla, se borra el usuario de Auth recién creado.

## Regla de choque

Una franja es el intervalo `[horaInicio, horaFin)`. Se solapan si `inicioA < finB` y `inicioB < finA`. Si el fin de una es el inicio de la otra, no chocan.

Ejemplos, misma cancha, miércoles:

- 16:00–18:00 contra 17:00–19:00: choque.
- 16:00–18:00 contra 18:00–19:00: permitido.
- Un evento el miércoles 16:30–17:30 choca con el deporte semanal de ese día.
- Un evento de otro miércoles no choca con un evento de otra fecha, aunque la hora se cruce.
- Un evento sí choca con el horario semanal si cae en ese día de la semana y las horas se cruzan.

La franja mínima es 30 minutos. El día va de 1 a 7. Las horas van de 0 a 1440 y el inicio es menor que el fin.

Se valida dos veces:

1. En el controlador, antes de guardar, para pintar el choque en rojo y deshabilitar Guardar. Eso es solo interfaz. Dos administradores pueden pasar esa revisión a la vez.
2. Dentro de la transacción de Firestore, al crear o mover el deporte o el evento. Toda escritura de reservas de esa cancha hace `canchas/{id}.version += 1`. Las transacciones del cliente no bloquean una consulta, solo los documentos leídos con `tx.get`. Al tocar `version`, el segundo guardado se reintenta, vuelve a leer las reservas y ve el choque.

Por eso las reglas deben dejar `reservas` y `canchas.version` solo al administrador. Si alguien escribe una reserva sin mover `version`, el candado no sirve.

## Por qué hay una FirebaseApp secundaria

`createUserWithEmailAndPassword` en la app por defecto inicia sesión con el usuario nuevo y echa al administrador. `GuardiaRol` vería rol `entrenador` y lo sacaría del panel.

`FirebaseServices` crea la app `crearCuentasAdmin` con las mismas options y llama a Auth en esa instancia. En web la persistencia de esa instancia es `NONE`. La sesión del admin no se reemplaza. El Admin SDK no se puede usar desde Flutter web; por eso la cuenta nace en el cliente y el documento `usuarios` lo escribe el admin ya autenticado en la app principal.

## Qué está simulado y qué falta

Simulado:

- PayPal. `PaypalVerificadorSimulado` acepta cualquier id no vacío y devuelve `fuente: 'simulado'`. El panel muestra "Verificación PayPal simulada". No hay llamada a la API de PayPal ni secreto en el cliente.
- El corte de solvencia lo dispara el botón, no un cron.

Falta, fuera de este módulo:

- Cloud Function `verificarPagoPaypal` (Orders v2, secreto en Secret Manager, `verificadoPor: 'paypal'`). Detalle en `docs/admin_firestore.md`.
- Opcional: `aplicarCortePagos` programada.
- Opcional: deshabilitar en Auth a los entrenadores desactivados. Hoy la cuenta sigue pudiendo entrar.
- `AuthController` no bloquea el login si `estado == 'inactivo'`. No se tocó a propósito.
- El estudiante todavía no tiene pantalla para crear tickets. El admin ya puede leerlos y responderlos.
- Reglas e índices: propuesta en `docs/admin_firestore.md`. No desplegar desde este repo.

## Prueba manual

Hacerla en el emulador o en un proyecto de pruebas. No en producción. No hace falta `firebase deploy` de reglas para leer este documento; sí hace falta el índice de `reservas` si se prueba contra un Firestore real de pruebas.

1. Entrar como administrador.
2. Crear una cancha.
3. Crear el deporte A: lunes y miércoles, 16:00–18:00, en esa cancha. Debe guardar.
4. Crear el deporte B en la misma cancha, miércoles 17:00–19:00. Debe bloquearse, en rojo, antes de guardar.
5. Cambiar B a miércoles 18:00–19:00. Debe guardar.
6. Crear un evento el mismo miércoles, 16:30–17:30, en esa cancha. Debe bloquearse.
7. Crear un entrenador con correo `@unimet.edu.ve`. La sesión del admin debe seguir en `/admin`.
8. Asignarlo al deporte A.
9. Desactivarlo mientras A sigue activo. Debe bloquearse y nombrar la disciplina.
10. Confirmar que no aparece un botón Eliminar en entrenadores ni en deportes.
