const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  writeBatch,
  addDoc,
  collection,
} = require('firebase/firestore');

let entorno;
const contextos = new Map();

function dbDe(uid) {
  if (!contextos.has(uid)) {
    contextos.set(uid, entorno.authenticatedContext(uid).firestore());
  }
  return contextos.get(uid);
}

async function poner(ruta, datos) {
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    await setDoc(doc(contexto.firestore(), ...ruta), datos, { merge: true });
  });
}

describe('correcciones A', () => {
  before(async () => {
    entorno = await initializeTestEnvironment({
      projectId: 'demo-saman-correcciones',
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
    contextos.clear();
    await poner(['usuarios', 'est1'], {
      rol: 'estudiante',
      estado: 'activo',
      solvente: true,
    });
    await poner(['usuarios', 'est2'], {
      rol: 'estudiante',
      estado: 'activo',
      solvente: true,
    });
    await poner(['usuarios', 'admin1'], {
      rol: 'administrador',
      estado: 'activo',
    });
    await poner(['deportes', 'dep1'], {
      nombre: 'Tenis',
      activo: true,
      cupos: 20,
      inscritos: 2,
    });
    await poner(['deportes', 'dep0'], {
      nombre: 'Vacio',
      activo: true,
      cupos: 20,
      inscritos: 0,
    });
    await poner(['resenas', 'propia'], {
      autorUid: 'est1',
      visible: true,
      deporteId: 'dep1',
      comentario: 'Mia',
      estrellas: 5,
    });
    await poner(['resenas', 'ajena'], {
      autorUid: 'est2',
      visible: true,
      deporteId: 'dep1',
      comentario: 'Suya',
      estrellas: 4,
    });
  });

  it('el estudiante borra su reseña, no la de otro, y el admin sí', async () => {
    await assertSucceeds(deleteDoc(doc(dbDe('est1'), 'resenas', 'propia')));
    await assertFails(deleteDoc(doc(dbDe('est1'), 'resenas', 'ajena')));
    await assertSucceeds(deleteDoc(doc(dbDe('admin1'), 'resenas', 'ajena')));
  });

  it('solo crea reseña si la inscripción está confirmada', async () => {
    await poner(['inscripciones', 'est1_dep1'], {
      estudianteUid: 'est1',
      deporteId: 'dep1',
      estado: 'confirmada',
    });
    await assertSucceeds(addDoc(collection(dbDe('est1'), 'resenas'), {
      autorUid: 'est1',
      visible: true,
      deporteId: 'dep1',
      comentario: 'Ok',
      estrellas: 5,
    }));

    await poner(['inscripciones', 'est1_dep1'], { estado: 'pendiente' });
    await assertFails(addDoc(collection(dbDe('est1'), 'resenas'), {
      autorUid: 'est1',
      visible: true,
      deporteId: 'dep1',
      comentario: 'Pendiente',
      estrellas: 5,
    }));

    await poner(['inscripciones', 'est1_dep1'], { estado: 'cancelada' });
    await assertFails(addDoc(collection(dbDe('est1'), 'resenas'), {
      autorUid: 'est1',
      visible: true,
      deporteId: 'dep1',
      comentario: 'Cancelada',
      estrellas: 5,
    }));

    await entorno.withSecurityRulesDisabled(async (contexto) => {
      const ref = doc(contexto.firestore(), 'inscripciones', 'est1_dep1');
      await deleteDoc(ref);
    });
    await assertFails(addDoc(collection(dbDe('est1'), 'resenas'), {
      autorUid: 'est1',
      visible: true,
      deporteId: 'dep1',
      comentario: 'Sin cupo',
      estrellas: 5,
    }));
  });

  it('cancelar con inscritos en 0 no exige bajar el contador', async () => {
    await poner(['inscripciones', 'est1_dep0'], {
      estudianteUid: 'est1',
      deporteId: 'dep0',
      estado: 'pendiente',
    });
    await assertSucceeds(updateDoc(doc(dbDe('est1'), 'inscripciones', 'est1_dep0'), {
      estado: 'cancelada',
    }));
    let inscritos;
    await entorno.withSecurityRulesDisabled(async (contexto) => {
      const snap = await getDoc(doc(contexto.firestore(), 'deportes', 'dep0'));
      inscritos = snap.data().inscritos;
    });
    if (inscritos !== 0) {
      throw new Error(`esperaba inscritos 0 y obtuvo ${inscritos}`);
    }
  });

  it('cancelar con inscritos en 2 exige bajar a 1 y no a -1', async () => {
    await poner(['inscripciones', 'est1_dep1'], {
      estudianteUid: 'est1',
      deporteId: 'dep1',
      estado: 'confirmada',
    });
    await assertFails(updateDoc(doc(dbDe('est1'), 'inscripciones', 'est1_dep1'), {
      estado: 'cancelada',
    }));

    const db = dbDe('est1');
    const baja = writeBatch(db);
    baja.update(doc(db, 'inscripciones', 'est1_dep1'), { estado: 'cancelada' });
    baja.update(doc(db, 'deportes', 'dep1'), { inscritos: 1 });
    await assertSucceeds(baja.commit());

    await poner(['inscripciones', 'est1_dep1'], { estado: 'confirmada' });
    await poner(['deportes', 'dep1'], { inscritos: 2 });
    const negativa = writeBatch(db);
    negativa.update(doc(db, 'inscripciones', 'est1_dep1'), { estado: 'cancelada' });
    negativa.update(doc(db, 'deportes', 'dep1'), { inscritos: -1 });
    await assertFails(negativa.commit());
  });
});
