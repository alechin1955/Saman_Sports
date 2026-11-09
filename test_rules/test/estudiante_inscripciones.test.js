const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} = require('firebase/firestore');

let entorno;
const contextos = new Map();

function dbDe(uid) {
  if (!contextos.has(uid)) {
    contextos.set(uid, entorno.authenticatedContext(uid).firestore());
  }
  return contextos.get(uid);
}

function datosInscripcion(uid, deporteId, estado, nombre) {
  return {
    estudianteUid: uid,
    deporteId,
    deporteNombre: nombre,
    estado,
    fecha: serverTimestamp(),
  };
}

async function sembrar() {
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    const db = contexto.firestore();
    const docs = {
      'usuarios/est1': { rol: 'estudiante', estado: 'activo', solvente: false },
      'usuarios/est2': { rol: 'estudiante', estado: 'activo', solvente: true },
      'usuarios/inactivo1': { rol: 'estudiante', estado: 'inactivo', solvente: true },
      'usuarios/admin1': { rol: 'administrador', estado: 'activo' },
      'deportes/dep1': { nombre: 'Tenis', activo: true, cupos: 20, inscritos: 1, entrenadorUid: 'ent1' },
      'deportes/dep2': { nombre: 'Futbol', activo: true, cupos: 20, inscritos: 0, entrenadorUid: 'ent2' },
      'deportes/depOff': { nombre: 'Cerrado', activo: false, cupos: 10, inscritos: 0, entrenadorUid: 'ent1' },
      'deportes/depLleno': { nombre: 'Lleno', activo: true, cupos: 2, inscritos: 2, entrenadorUid: 'ent1' },
      'deportes/dep1/asistencias/2026-11-08': { fecha: '2026-11-08', entrenadorUid: 'ent1', estados: {} },
      'deportes/dep2/asistencias/2026-11-08': { fecha: '2026-11-08', entrenadorUid: 'ent2', estados: {} },
    };
    for (const [ruta, datos] of Object.entries(docs)) {
      await setDoc(doc(db, ...ruta.split('/')), datos);
    }
  });
}

async function poner(ruta, datos) {
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    await setDoc(doc(contexto.firestore(), ...ruta), datos, { merge: true });
  });
}

function inscribir(uid, deporteId, nombre, inscritosAntes, estado = 'pendiente') {
  const db = dbDe(uid);
  const batch = writeBatch(db);
  batch.set(
    doc(db, 'inscripciones', `${uid}_${deporteId}`),
    datosInscripcion(uid, deporteId, estado, nombre),
  );
  batch.update(doc(db, 'deportes', deporteId), { inscritos: inscritosAntes + 1 });
  return batch.commit();
}

describe('inscripciones del estudiante', () => {
  before(async () => {
    entorno = await initializeTestEnvironment({
      projectId: 'demo-saman-estudiante',
      firestore: {
        rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
      },
    });
  });

  after(async () => {
    await entorno.cleanup();
  });

  beforeEach(async () => {
    contextos.clear();
    await entorno.clearFirestore();
    await sembrar();
  });

  it('el estudiante solvente (est2) crea su inscripción con +1 en la misma escritura', async () => {
    await assertSucceeds(inscribir('est2', 'dep2', 'Futbol', 0));
  });

  it('niega crear la inscripción de otro uid', async () => {
    const db = dbDe('est2');
    const batch = writeBatch(db);
    batch.set(doc(db, 'inscripciones', 'est1_dep2'), datosInscripcion('est1', 'dep2', 'pendiente', 'Futbol'));
    batch.update(doc(db, 'deportes', 'dep2'), { inscritos: 1 });
    await assertFails(batch.commit());
  });

  it('niega crear con estado confirmada', async () => {
    await assertFails(inscribir('est2', 'dep2', 'Futbol', 0, 'confirmada'));
  });

  it('niega crear sin subir inscritos', async () => {
    await assertFails(setDoc(
      doc(dbDe('est2'), 'inscripciones', 'est2_dep2'),
      datosInscripcion('est2', 'dep2', 'pendiente', 'Futbol'),
    ));
  });

  it('niega crear con el deporte lleno', async () => {
    await assertFails(inscribir('est2', 'depLleno', 'Lleno', 2));
  });

  it('niega crear en un deporte inactivo o inexistente', async () => {
    await assertFails(inscribir('est2', 'depOff', 'Cerrado', 0));
    await assertFails(setDoc(
      doc(dbDe('est2'), 'inscripciones', 'est2_noexiste'),
      datosInscripcion('est2', 'noexiste', 'pendiente', 'Fantasma'),
    ));
  });

  it('niega crear siendo no solvente y siendo inactivo', async () => {
    await assertFails(inscribir('est1', 'dep2', 'Futbol', 0));
    await assertFails(inscribir('inactivo1', 'dep2', 'Futbol', 0));
  });

  it('niega un +1 suelto si la inscripción ya está pendiente', async () => {
    await poner(['inscripciones', 'est2_dep2'], {
      estudianteUid: 'est2', deporteId: 'dep2', deporteNombre: 'Futbol', estado: 'pendiente',
    });
    await poner(['deportes', 'dep2'], { inscritos: 1 });
    await assertFails(updateDoc(doc(dbDe('est2'), 'deportes', 'dep2'), { inscritos: 2 }));
  });

  it('niega un -1 suelto si la inscripción ya está cancelada', async () => {
    await poner(['inscripciones', 'est2_dep2'], {
      estudianteUid: 'est2', deporteId: 'dep2', deporteNombre: 'Futbol', estado: 'cancelada',
    });
    await poner(['deportes', 'dep2'], { inscritos: 1 });
    await assertFails(updateDoc(doc(dbDe('est2'), 'deportes', 'dep2'), { inscritos: 0 }));
  });

  it('niega subir o bajar inscritos de dos en dos', async () => {
    await assertFails(updateDoc(doc(dbDe('est2'), 'deportes', 'dep2'), { inscritos: 2 }));
    await poner(['deportes', 'dep2'], { inscritos: 4 });
    await assertFails(updateDoc(doc(dbDe('est2'), 'deportes', 'dep2'), { inscritos: 2 }));
  });

  it('permite cancelar la propia con -1 y niega cancelar sin -1 o la de otro', async () => {
    await poner(['inscripciones', 'est2_dep2'], {
      estudianteUid: 'est2', deporteId: 'dep2', deporteNombre: 'Futbol', estado: 'pendiente',
    });
    await poner(['inscripciones', 'est1_dep2'], {
      estudianteUid: 'est1', deporteId: 'dep2', deporteNombre: 'Futbol', estado: 'pendiente',
    });
    await poner(['deportes', 'dep2'], { inscritos: 1 });

    const propia = dbDe('est2');
    const cancela = writeBatch(propia);
    cancela.update(doc(propia, 'inscripciones', 'est2_dep2'), { estado: 'cancelada' });
    cancela.update(doc(propia, 'deportes', 'dep2'), { inscritos: 0 });
    await assertSucceeds(cancela.commit());

    await poner(['inscripciones', 'est2_dep2'], { estado: 'pendiente' });
    await poner(['deportes', 'dep2'], { inscritos: 1 });
    await assertFails(updateDoc(doc(dbDe('est2'), 'inscripciones', 'est2_dep2'), { estado: 'cancelada' }));
    await assertFails(updateDoc(doc(dbDe('est1'), 'inscripciones', 'est2_dep2'), { estado: 'cancelada' }));
  });

  it('permite re-inscribirse de cancelada a pendiente con +1', async () => {
    await poner(['inscripciones', 'est2_dep2'], {
      estudianteUid: 'est2', deporteId: 'dep2', deporteNombre: 'Futbol', estado: 'cancelada',
    });
    const db = dbDe('est2');
    const batch = writeBatch(db);
    batch.update(doc(db, 'inscripciones', 'est2_dep2'), {
      estado: 'pendiente',
      fecha: serverTimestamp(),
    });
    batch.update(doc(db, 'deportes', 'dep2'), { inscritos: 1 });
    await assertSucceeds(batch.commit());
  });

  it('lee asistencia con inscripción pendiente o confirmada, y la niega si no hay o está cancelada', async () => {
    await poner(['inscripciones', 'est2_dep1'], {
      estudianteUid: 'est2', deporteId: 'dep1', estado: 'pendiente',
    });
    await poner(['deportes', 'depConf'], {
      nombre: 'Confirmado', activo: true, cupos: 10, inscritos: 1, entrenadorUid: 'ent1',
    });
    await poner(['deportes', 'depConf', 'asistencias', '2026-11-08'], {
      fecha: '2026-11-08', entrenadorUid: 'ent1', estados: {},
    });
    await poner(['inscripciones', 'est2_depConf'], {
      estudianteUid: 'est2', deporteId: 'depConf', estado: 'confirmada',
    });
    await poner(['deportes', 'depCanc'], {
      nombre: 'Cancelado', activo: true, cupos: 10, inscritos: 0, entrenadorUid: 'ent1',
    });
    await poner(['deportes', 'depCanc', 'asistencias', '2026-11-08'], {
      fecha: '2026-11-08', entrenadorUid: 'ent1', estados: {},
    });
    await poner(['inscripciones', 'est2_depCanc'], {
      estudianteUid: 'est2', deporteId: 'depCanc', estado: 'cancelada',
    });

    await assertSucceeds(getDoc(doc(dbDe('est2'), 'deportes', 'dep1', 'asistencias', '2026-11-08')));
    await assertSucceeds(getDoc(doc(dbDe('est2'), 'deportes', 'depConf', 'asistencias', '2026-11-08')));
    await assertFails(getDoc(doc(dbDe('est2'), 'deportes', 'dep2', 'asistencias', '2026-11-08')));
    await assertFails(getDoc(doc(dbDe('est2'), 'deportes', 'depCanc', 'asistencias', '2026-11-08')));
  });

  it('el admin cambia el estado de una inscripción', async () => {
    await poner(['inscripciones', 'est2_dep2'], {
      estudianteUid: 'est2', deporteId: 'dep2', estado: 'pendiente',
    });
    await assertSucceeds(updateDoc(
      doc(dbDe('admin1'), 'inscripciones', 'est2_dep2'),
      { estado: 'confirmada' },
    ));
  });
});
