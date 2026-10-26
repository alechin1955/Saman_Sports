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

## Asistencia por sesión

El registro se almacena en `deportes/{deporteId}/asistencias/{YYYY-MM-DD}`: `fecha` (día local), `entrenadorUid`, `estados` (mapa de ID de inscripción a `presente` o `ausente`) y `actualizadoEn` (marca del servidor). Los estados sin seleccionar permanecen pendientes; no se convierten automáticamente en ausencias. Es necesario completar toda la nómina antes de guardar. No se admiten fechas futuras.

Guardar usa una transacción para comprobar que la disciplina continúa asignada y que las inscripciones siguen confirmadas. El entrenador puede recuperar una sesión guardada y corregirla. Si falla una escritura, se mantiene el borrador para reintentar. El cambio de disciplina y fecha se bloquea con cambios pendientes; salir por el menú o retroceder solicita confirmación de descarte. Cerrar o recargar la pestaña puede perder cambios locales.

Las reglas desplegadas deben comprobar el rol, la asignación `entrenadorUid`, las inscripciones permitidas y los campos escritos dentro de la subcolección de asistencias. No se ha validado ni desplegado ese control en un proyecto Firebase real. Dos dispositivos que editen la misma sesión pueden sobrescribir el último registro; se recomienda coordinar la edición de cada sesión. Se limita el registro a 450 inscritos por sesión.

## Exportación del listado

El botón descarga un CSV en web o copia el CSV al portapapeles en otras plataformas. Incluye toda la nómina confirmada, independientemente del filtro de búsqueda, el estado guardado de la fecha elegida y el porcentaje acumulado hasta ese día. El porcentaje se calcula como presentes / sesiones con estado explícito para esa inscripción; las sesiones sin registro no cuentan como ausencias. Si no existe historial se muestra `Sin registros`.

La exportación consulta datos guardados; se bloquea mientras hay un borrador sin guardar. Un fallo al leer el historial no genera un archivo parcial. El CSV incluye BOM UTF-8, escapa comillas y separadores y neutraliza valores que podrían interpretarse como fórmulas. Las reglas del backend también deben autorizar la lectura del historial de la disciplina asignada.
