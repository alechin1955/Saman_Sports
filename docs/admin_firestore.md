# Firestore del administrador — reglas, índices y funciones

Este archivo es una propuesta para Giancarlo. **No está desplegado.** Este repositorio no contiene `firestore.rules` ni `firestore.indexes.json` a propósito: no hay que crearlos aquí ni correr `firebase deploy`.

Si el borrador ya desplegado tiene una excepción para que el estudiante cambie `deportes.inscritos` en ±1, hay que **conservarla**. No está en este repo, así que no se reescribe desde aquí.

## Hueco actual

En el borrador de reglas, `usuarios.solvente` no queda protegido. Un estudiante autenticado podría escribir `solvente: true` en su propio documento y aparecer como solvente sin un pago verificado. La regla de `usuarios` de abajo cierra ese hueco: el dueño no puede cambiar `rol`, `estado` ni `solvente`.

Otro hueco de producto, no de este archivo: `AuthController` no mira `usuarios.estado` al iniciar sesión. Desactivar a un entrenador en Firestore no lo saca de Auth. Eso pide Admin SDK (ver Cloud Functions).

## Funciones de rol

Copiar dentro del borrador de reglas. Ajustar nombres si el borrador ya define algo equivalente.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function firmado() {
      return request.auth != null;
    }

    function uid() {
      return request.auth.uid;
    }

    function rol() {
      return get(/databases/$(database)/documents/usuarios/$(uid())).data.rol;
    }

    function nombreUsuarioActual() {
      let usuario = get(/databases/$(database)/documents/usuarios/$(uid())).data;
      return usuario.nombre + ' ' + usuario.apellido;
    }

    function isAdmin() {
      return firmado() && rol() == 'administrador';
    }

    function isEstudiante() {
      return firmado() && rol() == 'estudiante';
    }

    function isEntrenador() {
      return firmado() && rol() == 'entrenador';
    }

    function soloCambia(campos) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(campos);
    }

    function sinCampos(campos) {
      return !request.resource.data.keys().hasAny(campos);
    }
  }
}
```

## Fragmentos por colección

### canchas, reservas, eventos, configuracion

Escritura solo del administrador. La lectura de canchas y eventos puede ser pública si el sitio estudiantil los muestra; si el borrador ya las restringe, no abrirlas.

El candado de horario solo funciona si **toda** escritura de `reservas` también incrementa `canchas/{id}.version`. Por eso `reservas` no puede ser escribible por el estudiante.

```
match /canchas/{id} {
  allow read: if true;
  allow create, update, delete: if isAdmin();
}

match /reservas/{id} {
  allow read: if isAdmin();
  allow create, update, delete: if isAdmin();
}

match /eventos/{id} {
  allow read: if firmado();
  allow create, update, delete: if isAdmin();
}

match /configuracion/{id} {
  allow read: if isAdmin();
  allow create, update: if isAdmin();
  allow delete: if false;
}
```

`configuracion/pagos` guarda `periodo`, `fechaInicio`, `fechaCorte` y `monto`.

### transacciones

Solo el administrador crea y lee. Sin update ni delete: es historial.

```
match /transacciones/{id} {
  allow read, create: if isAdmin();
  allow update, delete: if false;
}
```

### deportes

Escritura general: administrador. Excepción: el estudiante solo puede mover `inscritos` en exactamente +1 o -1 y no puede tocar el resto. Si esa excepción ya está desplegada, copiarla tal cual y no sustituirla por este bloque.

El administrador también mueve `inscritos` al confirmar, cancelar o reactivar una inscripción. Esa escritura entra por `isAdmin()`.

```
match /deportes/{id} {
  allow read: if true;

  allow create, delete: if isAdmin();

  allow update: if isAdmin()
    || (
      isEstudiante()
      && soloCambia(['inscritos'])
      && request.resource.data.inscritos is int
      && resource.data.inscritos is int
      && (
        request.resource.data.inscritos == resource.data.inscritos + 1
        || request.resource.data.inscritos == resource.data.inscritos - 1
      )
      && request.resource.data.inscritos >= 0
    );
}
```

Campos que escribe el admin y que el borrador de main-2 no tenía: `canchaId`, `canchaNombre`, `horarios` (lista de `{dia, horaInicio, horaFin}`), además del `horario` legible que ya existía.

### entrenadores

Lectura pública. Escritura solo del administrador. El perfil público no lleva `cedula`, `correo` ni `telefono`.

```
match /entrenadores/{id} {
  allow read: if true;
  allow create, update, delete: if isAdmin();
}
```

### usuarios

El administrador puede crear un documento con `rol == 'entrenador'` (la cuenta se crea desde la app, no con Admin SDK) y puede actualizar `estado`, `solvente`, `nombre`, `apellido` y `telefono`.

El propio usuario no puede cambiar `rol`, `estado` ni `solvente`. Este es el cierre del hueco de solvencia.

```
match /usuarios/{userId} {
  allow read: if isAdmin() || (firmado() && uid() == userId);

  allow create: if isAdmin()
    && request.resource.data.rol == 'entrenador'
    && request.resource.data.estado == 'activo'
    && !request.resource.data.keys().hasAny(['clave', 'password']);

  allow update: if isAdmin()
      && soloCambia(['estado', 'solvente', 'nombre', 'apellido', 'telefono'])
    || (
      firmado()
      && uid() == userId
      && soloCambia(['nombre', 'apellido', 'telefono'])
      && request.resource.data.rol == resource.data.rol
      && request.resource.data.estado == resource.data.estado
      && request.resource.data.solvente == resource.data.solvente
    );

  allow delete: if false;
}
```

Si el estudiante ya puede editar más campos de su perfil en el borrador actual, ampliar `soloCambia` del dueño con esos campos, pero **nunca** incluir `rol`, `estado` ni `solvente`.

### pagos

El estudiante crea solo el suyo, con `verificado == false` y sin `verificadoPor` ni `fechaPago`. No puede actualizarlo.

Solo el administrador (simulado, hoy) o la Cloud Function con Admin SDK (real) actualizan `verificado`, `verificadoPor`, `fechaPago`, `paypalOrderId` y `estado`.

En producción, rechazar desde el cliente `verificadoPor == 'paypal'`. Ese valor lo escribe únicamente `verificarPagoPaypal`. El cliente del admin, mientras el verificador sea el simulado, escribe `verificadoPor: 'simulado'`.

```
match /pagos/{id} {
  allow read: if isAdmin()
    || (isEstudiante() && resource.data.estudianteUid == uid());

  allow create: if isEstudiante()
    && request.resource.data.estudianteUid == uid()
    && request.resource.data.verificado == false
    && sinCampos(['verificadoPor', 'fechaPago', 'verificadoEn']);

  allow update: if isAdmin()
    && request.resource.data.verificadoPor != 'paypal';

  allow delete: if false;
}
```

La Cloud Function no pasa por estas reglas: usa Admin SDK.

### resenas

El administrador solo cambia `visible`. Crear, editar y borrar el comentario sigue siendo del autor, como ya hace el módulo estudiante.

```
match /resenas/{id} {
  allow read: if resource.data.visible == true || isAdmin()
    || (firmado() && resource.data.autorUid == uid());

  allow update: if isAdmin() && soloCambia(['visible'])
    || (
      firmado()
      && resource.data.autorUid == uid()
      && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['visible'])
    );

  allow delete: if firmado() && resource.data.autorUid == uid();
}
```

La línea del autor es un recordatorio: no dejar que el admin reescriba `comentario` o `estrellas` desde el panel. El panel solo llama a cambiar visibilidad.

### tickets

Cada estudiante o entrenador crea y lee solo los suyos (`autorUid == uid`). El administrador lee todos y solo actualiza `respuesta`, `estado` y `resueltoEn`.

```
match /tickets/{id} {
  allow read: if isAdmin()
    || (firmado() && resource.data.autorUid == uid());

  allow create: if (isEstudiante() || isEntrenador())
    && request.resource.data.keys().hasOnly([
      'asunto', 'categoria', 'descripcion', 'autorUid', 'autorNombre',
      'autorRol', 'estado', 'respuesta', 'fecha', 'resueltoEn'
    ])
    && request.resource.data.autorUid == uid()
    && request.resource.data.autorNombre == nombreUsuarioActual()
    && request.resource.data.autorRol == rol()
    && request.resource.data.estado == 'abierto'
    && request.resource.data.respuesta == ''
    && request.resource.data.resueltoEn == null
    && request.resource.data.fecha == request.time
    && request.resource.data.categoria in [
      'cuenta', 'disciplinas', 'asistencia', 'eventos', 'otro'
    ]
    && request.resource.data.asunto is string
    && request.resource.data.asunto.size() >= 5
    && request.resource.data.asunto.size() <= 80
    && request.resource.data.descripcion is string
    && request.resource.data.descripcion.size() >= 10
    && request.resource.data.descripcion.size() <= 500;

  allow update: if isAdmin()
    && soloCambia(['respuesta', 'estado', 'resueltoEn']);

  allow delete: if false;
}
```

La comparación de `autorNombre` supone que los perfiles tienen `nombre` y `apellido`, como exige el registro actual. Si el esquema remoto admite perfiles antiguos sin esos campos, hay que normalizarlos antes de desplegar esta regla; no se debe reemplazar la comparación por un nombre enviado libremente por el cliente.

### notificaciones

El administrador las crea (hoy, aviso de pago pendiente, id `pago-{periodo}-{uid}`). El destinatario las lee y solo puede marcar `leida`.

```
match /notificaciones/{id} {
  allow read: if isAdmin()
    || (firmado() && resource.data.destinatarioUid == uid());

  allow create: if isAdmin();

  allow update: if firmado()
    && resource.data.destinatarioUid == uid()
    && soloCambia(['leida']);

  allow delete: if false;
}
```

## Índices

### Hace falta este compuesto

`streamReservasCancha` filtra y ordena así:

- colección `reservas`
- `canchaId` ASC, igualdad
- `activa` ASC, igualdad
- `dia` ASC
- `horaInicio` ASC

Índice compuesto, campos en ese orden, todos ASC. El comentario en `FirebaseServices.streamReservasCancha` lo pide explícitamente.

Si en consola aparece `failed-precondition` con un enlace, ese enlace crea el índice que falta. Usar ese enlace es más seguro que inventar otro índice.

### No crear índices de más

Estas consultas no necesitan índice compuesto. Una igualdad, o varias igualdades sin `orderBy`, o un solo `orderBy`, las cubre el índice automático de un campo.

Igualdades, sin orden:

- `canchas` where `nombre` ==
- `reservas` where `canchaId` == y `activa` == (el choque y el conteo de ocupación; no ordenan)
- `reservas` where `refId` == y `tipo` ==
- `usuarios` where `rol` ==
- `deportes` where `entrenadorUid` ==
- `deportes` where `activo` ==
- `entrenadores` where `activo` ==
- `canchas` where `activa` ==
- `inscripciones` where `estado` ==
- `pagos` where `estado` ==
- `resenas` where `visible` ==
- `tickets` where `estado` ==
- `eventos` where `estado` ==

Un solo `orderBy`, sin filtro:

- `canchas` orderBy `nombre`
- `deportes` orderBy `nombre` (listado admin)
- `entrenadores` orderBy `nombre`
- `eventos` orderBy `fecha`
- `resenas` orderBy `fecha` (listado admin)
- `inscripciones` orderBy `fecha`
- `pagos` orderBy `fecha`
- `tickets` orderBy `fecha`
- `transacciones` orderBy `fecha` + `limit`

Ya existían en main-2, y no son de este módulo, estas combinaciones de filtro + orden. No duplicarlas si ya están desplegadas:

- `deportes` where `activo` == orderBy `nombre`
- `entrenadores` where `activo` == orderBy `nombre`
- `resenas` where `visible` == orderBy `fecha`
- `resenas` where `autorUid` == orderBy `fecha`

## Cloud Functions pendientes

No implementarlas en Flutter. El secreto de PayPal no puede vivir en web.

### verificarPagoPaypal

- Disparo: callable, solo si `usuarios/{uid}.rol == 'administrador'`, o escritura de servidor. No confiar en un campo que mande el cliente.
- Llama a Orders v2: `GET /v2/checkout/orders/{id}`.
- El client id / secret van en Secret Manager, no en `FirebaseServices` ni en el cliente.
- Aceptar solo si el estado es `COMPLETED`, la moneda cuadra y el monto es el de `pagos/{id}.monto`.
- Escribir en el pago, con Admin SDK: `verificado: true`, `verificadoPor: 'paypal'`, `fechaPago`, `paypalOrderId`, `idTransaccion`, `verificadoEn`, `estado: 'realizado'`.
- Si falla, no marcar verificado. Devolver el error al panel.
- Hoy el cliente usa `PaypalVerificadorSimulado` y escribe `verificadoPor: 'simulado'`. Para cambiarlo se inyecta otra clase `PaypalVerificador` en `AdminPagoController`. El panel no debería decir "verificado" sin la palabra "simulado" mientras la fuente sea `simulado`.

### aplicarCortePagos (opcional)

Hoy el administrador pulsa "Aplicar corte" y el cliente recorre estudiantes activos, calcula solvencia y escribe `usuarios.solvente` más una notificación. Una función programada puede hacer lo mismo después de `fechaCorte` a las 23:59:59. No hace falta para que el botón actual funcione.

### Deshabilitar Auth del entrenador (opcional)

`cambiarEstadoEntrenador` pone `entrenadores.activo` y `usuarios.estado`, pero la cuenta de Auth sigue habilitada. Deshabilitarla pide Admin SDK (`auth.updateUser(uid, { disabled: true })`). Además, `AuthController` no revisa `estado` al entrar: aunque la función exista, el login del cliente seguiría aceptando al entrenador inactivo hasta que alguien cambie ese controlador. Eso está fuera de este módulo.
