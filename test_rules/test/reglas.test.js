const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const proyecto = 'demo-saman';
let entorno;

const contextos = new Map();

function dbDe(uid) {
  const clave = uid || '';
  if (!contextos.has(clave)) {
    contextos.set(
      clave,
      uid
        ? entorno.authenticatedContext(uid).firestore()
        : entorno.unauthenticatedContext().firestore(),
    );
  }
  return contextos.get(clave);
}

async function sembrar() {
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    const db = contexto.firestore();
    const usuarios = {
      est1: { rol: 'estudiante', estado: 'activo', nombre: 'Ana', apellido: 'Ruiz', telefono: '04141234567', solvente: false },
      est2: { rol: 'estudiante', estado: 'activo', nombre: 'Luis', apellido: 'Paz', telefono: '04141234568', solvente: true },
      ent1: { rol: 'entrenador', estado: 'activo', nombre: 'Juan', apellido: 'Pérez', telefono: '04141234569' },
      ent2: { rol: 'entrenador', estado: 'activo', nombre: 'Marta', apellido: 'Diaz', telefono: '04141234560' },
      admin1: { rol: 'administrador', estado: 'activo', nombre: 'Admin', apellido: 'Saman' },
      inactivo1: { rol: 'estudiante', estado: 'inactivo', nombre: 'Ina', apellido: 'Activa', solvente: false },
    };
    for (const [id, datos] of Object.entries(usuarios)) {
      await setDoc(doc(db, 'usuarios', id), datos);
    }
    await setDoc(doc(db, 'deportes', 'dep1'), {
      nombre: 'Tenis', descripcion: 'Cancha norte', activo: true, entrenadorUid: 'ent1',
      cupos: 20, inscritos: 1, canchaId: 'c1',
    });
    await setDoc(doc(db, 'deportes', 'dep2'), {
      nombre: 'Futbol', descripcion: 'Otra', activo: true, entrenadorUid: 'ent2',
      cupos: 20, inscritos: 0, canchaId: 'c1',
    });
    await setDoc(doc(db, 'deportes', 'depOff'), {
      nombre: 'Cerrado', descripcion: 'Inactivo', activo: false, entrenadorUid: 'ent1',
      cupos: 10, inscritos: 0, canchaId: 'c1',
    });
    await setDoc(doc(db, 'entrenadores', 'ent1'), { nombre: 'Juan', activo: true });
    await setDoc(doc(db, 'entrenadores', 'entOff'), { nombre: 'Viejo', activo: false });
    await setDoc(doc(db, 'canchas', 'c1'), { nombre: 'Norte', activa: true, version: 0 });
    await setDoc(doc(db, 'canchas', 'cOff'), { nombre: 'Sur', activa: false, version: 0 });
    await setDoc(doc(db, 'eventos', 'ev1'), {
      titulo: 'Torneo', estado: 'pendiente', creadoPorUid: 'ent1', deporteId: 'dep1', activo: false,
    });
    await setDoc(doc(db, 'resenas', 'r1'), {
      autorUid: 'est1', visible: true, deporteId: 'dep1', comentario: 'Bien', estrellas: 5,
    });
    await setDoc(doc(db, 'resenas', 'rHide'), {
      autorUid: 'est2', visible: false, deporteId: 'dep1', comentario: 'Oculta', estrellas: 1,
    });
    await setDoc(doc(db, 'reservas', 'res1'), {
      canchaId: 'c1', activa: true, refId: 'dep1', tipo: 'deporte', dia: 1, horaInicio: 8, horaFin: 9,
    });
    await setDoc(doc(db, 'pagos', 'p1'), {
      estudianteUid: 'est1', verificado: false, estado: 'pendiente', monto: 10,
    });
    await setDoc(doc(db, 'inscripciones', 'i1'), {
      estudianteUid: 'est1', deporteId: 'dep1', estado: 'confirmada',
    });
    await setDoc(doc(db, 'notificaciones', 'n1'), {
      destinatarioUid: 'est1', leida: false, titulo: 'Pago', mensaje: 'Pendiente',
    });
    await setDoc(doc(db, 'tickets', 't1'), {
      autorUid: 'ent1', autorRol: 'entrenador', estado: 'abierto', respuesta: '', resueltoEn: null, asunto: 'Ayuda',
    });
    await setDoc(doc(db, 'configuracion', 'pagos'), { periodo: '2026-1', monto: 10 });
    await setDoc(doc(db, 'transacciones', 'tx1'), { usuarioUid: 'admin1', accion: 'crear', modulo: 'deportes' });
    await setDoc(doc(db, 'deportes', 'dep1', 'asistencias', '2026-11-08'), {
      fecha: '2026-11-08', entrenadorUid: 'ent1', estados: { i1: 'presente' },
    });
  });
}

before(async () => {
  entorno = await initializeTestEnvironment({
    projectId: proyecto,
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await entorno.cleanup();
});

beforeEach(async () => {
  await entorno.clearFirestore();
  await sembrar();
});

describe('sin login', () => {
  it('niega leer usuarios', async () => {
    await assertFails(getDoc(doc(dbDe(null), 'usuarios', 'est1')));
  });

  it('permite deportes, entrenadores y canchas activos, y reseñas visibles', async () => {
    const db = dbDe(null);
    await assertSucceeds(getDocs(query(collection(db, 'deportes'), where('activo', '==', true))));
    await assertSucceeds(getDocs(query(collection(db, 'entrenadores'), where('activo', '==', true))));
    await assertSucceeds(getDocs(query(collection(db, 'canchas'), where('activa', '==', true))));
    await assertSucceeds(getDocs(query(collection(db, 'resenas'), where('visible', '==', true))));
  });

  it('niega inactivos, reseñas ocultas y listados sin filtro', async () => {
    const db = dbDe(null);
    await assertFails(getDoc(doc(db, 'deportes', 'depOff')));
    await assertFails(getDoc(doc(db, 'entrenadores', 'entOff')));
    await assertFails(getDoc(doc(db, 'canchas', 'cOff')));
    await assertFails(getDoc(doc(db, 'resenas', 'rHide')));
    await assertFails(getDocs(collection(db, 'deportes')));
  });
});

describe('estudiante', () => {
  it('lee su usuario y no el de otro', async () => {
    const db = dbDe('est1');
    await assertSucceeds(getDoc(doc(db, 'usuarios', 'est1')));
    await assertFails(getDoc(doc(db, 'usuarios', 'est2')));
  });

  it('edita nombre o teléfono y no rol, estado ni solvente', async () => {
    const db = dbDe('est1');
    await assertSucceeds(updateDoc(doc(db, 'usuarios', 'est1'), { nombre: 'Ana María', telefono: '04140000000' }));
    await assertFails(updateDoc(doc(db, 'usuarios', 'est1'), { solvente: true }));
    await assertFails(updateDoc(doc(db, 'usuarios', 'est1'), { rol: 'administrador' }));
    await assertFails(updateDoc(doc(db, 'usuarios', 'est1'), { estado: 'inactivo' }));
  });

  it('al registrarse solo puede crear rol estudiante', async () => {
    const db = dbDe('nuevo');
    await assertSucceeds(setDoc(doc(db, 'usuarios', 'nuevo'), {
      rol: 'estudiante', nombre: 'Nuevo', estado: 'activo', solvente: false,
    }));
    await assertFails(setDoc(doc(dbDe('intruso'), 'usuarios', 'intruso'), {
      rol: 'administrador', nombre: 'Trampa', estado: 'activo',
    }));
  });

  it('crea una reseña con su uid y no con otro', async () => {
    const db = dbDe('est1');
    await assertSucceeds(addDoc(collection(db, 'resenas'), {
      autorUid: 'est1', visible: true, deporteId: 'dep1', comentario: 'Nueva', estrellas: 4,
    }));
    await assertFails(addDoc(collection(db, 'resenas'), {
      autorUid: 'est2', visible: true, deporteId: 'dep1', comentario: 'Ajena', estrellas: 4,
    }));
  });

  it('no marca un pago como verificado', async () => {
    const db = dbDe('est1');
    await assertFails(updateDoc(doc(db, 'pagos', 'p1'), { verificado: true, estado: 'realizado' }));
  });

  it('lee sus notificaciones y solo cambia leida', async () => {
    const db = dbDe('est1');
    await assertSucceeds(getDocs(query(collection(db, 'notificaciones'), where('destinatarioUid', '==', 'est1'))));
    await assertSucceeds(updateDoc(doc(db, 'notificaciones', 'n1'), { leida: true }));
    await assertFails(updateDoc(doc(db, 'notificaciones', 'n1'), { titulo: 'Cambiado' }));
  });
});

describe('usuario inactivo', () => {
  it('puede leer su propio usuario para que el login vea el estado', async () => {
    await assertSucceeds(getDoc(doc(dbDe('inactivo1'), 'usuarios', 'inactivo1')));
  });

  it('niega el resto de lecturas privadas', async () => {
    const db = dbDe('inactivo1');
    await assertFails(getDoc(doc(db, 'usuarios', 'est1')));
    await assertFails(getDoc(doc(db, 'pagos', 'p1')));
    await assertFails(getDoc(doc(db, 'notificaciones', 'n1')));
    await assertFails(getDoc(doc(db, 'configuracion', 'pagos')));
    await assertFails(getDocs(query(collection(db, 'notificaciones'), where('destinatarioUid', '==', 'inactivo1'))));
  });
});

describe('entrenador', () => {
  it('actualiza la descripción de su deporte y no el de otro ni campos de catálogo', async () => {
    const db = dbDe('ent1');
    await assertSucceeds(updateDoc(doc(db, 'deportes', 'dep1'), { descripcion: 'Horario de tarde' }));
    await assertFails(updateDoc(doc(db, 'deportes', 'dep2'), { descripcion: 'Ajeno' }));
    await assertFails(updateDoc(doc(db, 'deportes', 'dep1'), { cupos: 99 }));
    await assertFails(updateDoc(doc(db, 'deportes', 'dep1'), { entrenadorUid: 'ent2' }));
  });

  it('guarda la asistencia de su deporte y no la de otro', async () => {
    const db = dbDe('ent1');
    await assertSucceeds(setDoc(doc(db, 'deportes', 'dep1', 'asistencias', '2026-11-09'), {
      fecha: '2026-11-09', entrenadorUid: 'ent1', estados: { i1: 'ausente' }, actualizadoEn: new Date(),
    }));
    await assertFails(setDoc(doc(db, 'deportes', 'dep2', 'asistencias', '2026-11-09'), {
      fecha: '2026-11-09', entrenadorUid: 'ent1', estados: {}, actualizadoEn: new Date(),
    }));
  });

  it('lee las reservas activas de una cancha', async () => {
    const db = dbDe('ent1');
    await assertSucceeds(getDocs(query(
      collection(db, 'reservas'),
      where('canchaId', '==', 'c1'),
      where('activa', '==', true),
    )));
  });

  it('crea un ticket propio y no responde tickets', async () => {
    const db = dbDe('ent1');
    await assertSucceeds(addDoc(collection(db, 'tickets'), {
      autorUid: 'ent1', autorRol: 'entrenador', estado: 'abierto', respuesta: '', resueltoEn: null,
      asunto: 'No puedo entrar', categoria: 'cuenta', descripcion: 'Falla el acceso',
    }));
    await assertFails(updateDoc(doc(db, 'tickets', 't1'), { respuesta: 'Yo mismo', estado: 'resuelto' }));
  });
});

describe('admin', () => {
  it('cambia estado y solvente, crea un deporte y oculta una reseña', async () => {
    const db = dbDe('admin1');
    await assertSucceeds(updateDoc(doc(db, 'usuarios', 'est1'), { estado: 'inactivo', solvente: true }));
    await assertSucceeds(setDoc(doc(db, 'deportes', 'depNuevo'), {
      nombre: 'Voleibol', descripcion: 'Nueva', activo: true, entrenadorUid: '', cupos: 12, inscritos: 0,
    }));
    await assertSucceeds(updateDoc(doc(db, 'resenas', 'r1'), { visible: false }));
  });

  it('marca un pago como verificado mientras no exista la Cloud Function', async () => {
    await assertSucceeds(updateDoc(doc(dbDe('admin1'), 'pagos', 'p1'), { verificado: true, estado: 'realizado' }));
  });
});

describe('rutas y configuración', () => {
  it('niega una ruta no declarada', async () => {
    await assertFails(getDoc(doc(dbDe('admin1'), 'secreto', 'x')));
    await assertFails(getDocs(collection(dbDe(null), 'asistencias')));
  });

  it('deja leer la configuración de pagos con sesión activa y escribirla solo al admin', async () => {
    await assertSucceeds(getDoc(doc(dbDe('est1'), 'configuracion', 'pagos')));
    await assertFails(getDoc(doc(dbDe(null), 'configuracion', 'pagos')));
    await assertFails(updateDoc(doc(dbDe('est1'), 'configuracion', 'pagos'), { monto: 1 }));
    await assertSucceeds(updateDoc(doc(dbDe('admin1'), 'configuracion', 'pagos'), { monto: 20 }));
  });
});

describe('consultas de FirebaseServices', () => {
  const casos = [
    ['público deportes activo', null, 'deportes', [where('activo', '==', true)], true],
    ['público entrenadores activo', null, 'entrenadores', [where('activo', '==', true)], true],
    ['público reseñas visible', null, 'resenas', [where('visible', '==', true)], true],
    ['entrenador notificaciones destinatarioUid', 'ent1', 'notificaciones', [where('destinatarioUid', '==', 'ent1')], true],
    ['entrenador canchas sin filtro', 'ent1', 'canchas', [orderBy('nombre')], true],
    ['admin canchas orderBy nombre', 'admin1', 'canchas', [orderBy('nombre')], true],
    ['entrenador reservas canchaId+activa', 'ent1', 'reservas', [where('canchaId', '==', 'c1'), where('activa', '==', true)], true],
    ['entrenador reseñas deporteId+visible', 'ent1', 'resenas', [where('deporteId', '==', 'dep1'), where('visible', '==', true)], true],
    ['entrenador deportes entrenadorUid', 'ent1', 'deportes', [where('entrenadorUid', '==', 'ent1')], true],
    ['entrenador inscripciones solo deporteId', 'ent1', 'inscripciones', [where('deporteId', '==', 'dep1')], true],
    ['admin inscripciones deporteId+estado', 'admin1', 'inscripciones', [where('deporteId', '==', 'dep1'), where('estado', '==', 'confirmada')], true],
    ['entrenador eventos creadoPorUid', 'ent1', 'eventos', [where('creadoPorUid', '==', 'ent1')], true],
    ['entrenador tickets autorUid', 'ent1', 'tickets', [where('autorUid', '==', 'ent1')], true],
    ['estudiante reseñas autorUid+fecha', 'est1', 'resenas', [where('autorUid', '==', 'est1'), orderBy('fecha', 'desc')], true],
    ['admin canchas nombre', 'admin1', 'canchas', [where('nombre', '==', 'Norte')], true],
    ['admin deportes orderBy nombre', 'admin1', 'deportes', [orderBy('nombre')], true],
    ['admin reservas refId+tipo', 'admin1', 'reservas', [where('refId', '==', 'dep1'), where('tipo', '==', 'deporte')], true],
    ['admin entrenadores orderBy nombre', 'admin1', 'entrenadores', [orderBy('nombre')], true],
    ['admin usuarios rol entrenador', 'admin1', 'usuarios', [where('rol', '==', 'entrenador')], true],
    ['admin eventos orderBy fecha', 'admin1', 'eventos', [orderBy('fecha', 'desc')], true],
    ['admin usuarios rol estudiante', 'admin1', 'usuarios', [where('rol', '==', 'estudiante')], true],
    ['admin reseñas orderBy fecha', 'admin1', 'resenas', [orderBy('fecha', 'desc')], true],
    ['admin inscripciones orderBy fecha', 'admin1', 'inscripciones', [orderBy('fecha', 'desc')], true],
    ['admin pagos orderBy fecha', 'admin1', 'pagos', [orderBy('fecha', 'desc')], true],
    ['admin pagos estudianteUid', 'admin1', 'pagos', [where('estudianteUid', '==', 'est1')], true],
    ['admin tickets orderBy fecha', 'admin1', 'tickets', [orderBy('fecha', 'desc')], true],
    ['admin transacciones orderBy fecha', 'admin1', 'transacciones', [orderBy('fecha', 'desc')], true],
    ['admin canchas activa', 'admin1', 'canchas', [where('activa', '==', true)], true],
    ['admin inscripciones estado', 'admin1', 'inscripciones', [where('estado', '==', 'confirmada')], true],
    ['admin pagos estado', 'admin1', 'pagos', [where('estado', '==', 'pendiente')], true],
    ['admin reseñas visible false', 'admin1', 'resenas', [where('visible', '==', false)], true],
    ['admin tickets estado', 'admin1', 'tickets', [where('estado', '==', 'abierto')], true],
    ['admin eventos estado', 'admin1', 'eventos', [where('estado', '==', 'aprobado')], true],
    ['estudiante usuarios de otro alumno', 'est1', 'usuarios', [where('rol', '==', 'estudiante')], false],
  ];

  for (const [nombre, uid, coleccion, filtros, permitido] of casos) {
    it(`${permitido ? 'permite' : 'bloquea'}: ${nombre}`, async () => {
      const consulta = query(collection(dbDe(uid), coleccion), ...filtros);
      if (permitido) await assertSucceeds(getDocs(consulta));
      else await assertFails(getDocs(consulta));
    });
  }

  it('permite al entrenador leer la asistencia de su disciplina', async () => {
    await assertSucceeds(getDocs(collection(dbDe('ent1'), 'deportes', 'dep1', 'asistencias')));
  });

  it('permite al entrenador leer el perfil de un alumno', async () => {
    await assertSucceeds(getDoc(doc(dbDe('ent1'), 'usuarios', 'est1')));
    await assertFails(getDoc(doc(dbDe('ent1'), 'usuarios', 'admin1')));
  });

  it('permite al entrenador leer una inscripción concreta de su disciplina', async () => {
    await assertSucceeds(getDoc(doc(dbDe('ent1'), 'inscripciones', 'i1')));
  });
});

describe('permisos temporales', () => {
  it('solo el admin actualiza un pago', async () => {
    await assertSucceeds(updateDoc(doc(dbDe('admin1'), 'pagos', 'p1'), { verificado: true, estado: 'realizado' }));
    await assertFails(updateDoc(doc(dbDe('est1'), 'pagos', 'p1'), { verificado: true }));
    await assertFails(updateDoc(doc(dbDe(null), 'pagos', 'p1'), { verificado: true }));
  });

  it('el entrenador lista inscripciones por deporte y los demás no', async () => {
    const filtro = [where('deporteId', '==', 'dep1')];
    await assertSucceeds(getDocs(query(collection(dbDe('ent1'), 'inscripciones'), ...filtro)));
    await assertFails(getDocs(query(collection(dbDe('est1'), 'inscripciones'), ...filtro)));
    await assertFails(getDocs(query(collection(dbDe(null), 'inscripciones'), ...filtro)));
  });

  it('el entrenador lee un alumno y los demás no leen usuarios ajenos', async () => {
    await assertSucceeds(getDoc(doc(dbDe('ent1'), 'usuarios', 'est1')));
    await assertFails(getDoc(doc(dbDe('est1'), 'usuarios', 'est2')));
    await assertFails(getDoc(doc(dbDe(null), 'usuarios', 'est1')));
  });

  it('el entrenador lista canchas y lee una inactiva; estudiante y anónimo no', async () => {
    await assertSucceeds(getDocs(query(collection(dbDe('ent1'), 'canchas'), orderBy('nombre'))));
    await assertSucceeds(getDoc(doc(dbDe('ent1'), 'canchas', 'cOff')));
    await assertFails(getDocs(query(collection(dbDe('est1'), 'canchas'), orderBy('nombre'))));
    await assertFails(getDoc(doc(dbDe('est1'), 'canchas', 'cOff')));
    await assertFails(getDocs(query(collection(dbDe(null), 'canchas'), orderBy('nombre'))));
    await assertFails(getDoc(doc(dbDe(null), 'canchas', 'cOff')));
  });
});
