# Módulo del entrenador

La ruta `/entrenador` y la restauración de sesión comparten el panel adaptable del estudiante y conservan la validación del rol entrenador.

## Contrato de datos

- `deportes/{id}`: campos existentes del catálogo y `entrenadorUid` (UID de Firebase Auth del entrenador asignado), `activo: true`. El nombre visible del entrenador no se usa como identificador de asignación.
- `inscripciones/{id}`: `deporteId`, `estudianteUid`, `estado: confirmada`. Las inscripciones pendientes y canceladas no forman parte de la nómina.
- `usuarios/{estudianteUid}`: `nombre`, `apellido`, `carnet`, `correo`.

Si no existen asignaciones se muestra un estado vacío. Los fallos de conexión o permisos se muestran como errores recuperables; no se insertan estudiantes ficticios.

## Integración con Firebase

El backend debe proporcionar `entrenadorUid` al asignar disciplinas. Los documentos antiguos que solo tienen `entrenadorNombre` no aparecen como asignados. La consulta del cliente no sustituye reglas de seguridad: las reglas de Firestore deben permitir al entrenador leer únicamente las inscripciones y los datos de alumnos necesarios de sus disciplinas. Este repositorio no contiene reglas de Firestore para verificar ese despliegue. El módulo no modifica reglas ni datos remotos durante sus pruebas.

Las pruebas usan un repositorio inyectado para verificar búsqueda, selección concurrente, errores, estados vacíos y tamaños de pantalla sin depender de cuentas reales.
