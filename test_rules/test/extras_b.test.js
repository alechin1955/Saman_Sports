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
  getDocs,
  collection,
  setDoc,
  updateDoc,
  writeBatch,
  serverTimestamp,
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

describe('extras B', () => {
  before(async () => {
    entorno = await initializeTestEnvironment({
      projectId: 'demo-saman-extras-b',
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
    await poner(['usuarios', 'ent1'], { rol: 'entrenador', estado: 'activo' });
    await poner(['usuarios', 'ent2'], { rol: 'entrenador', estado: 'activo' });
    await poner(['usuarios', 'est1'], {
      rol: 'estudiante',
      estado: 'activo',
      cedula: 'V-1',
      carnet: '111',
      telefono: '04120000000',
    });
    await poner(['usuarios', 'admin1'], { rol: 'administrador', estado: 'activo' });
    await poner(['deportes', 'dep1'], {
      nombre: 'Tenis',
      activo: true,
      entrenadorUid: 'ent1',
      cupos: 10,
      inscritos: 1,
    });
    await poner(['entrenadores', 'ent1'], {
      nombre: 'Ana',
      activo: true,
      especialidad: 'Campo',
    });
    await poner(['entrenadores', 'ent2'], { nombre: 'Luis', activo: true });
    await poner(['eventos', 'ev1'], {
      creadoPorUid: 'ent1',
      estado: 'pendiente',
      deporteId: 'dep1',
      titulo: 'Torneo',
      fecha: '2026-12-01',
    });
    await poner(['eventos', 'ev2'], {
      creadoPorUid: 'ent2',
      estado: 'pendiente',
      deporteId: 'dep1',
      titulo: 'Ajeno',
    });
    await poner(['eventos', 'evOk'], {
      creadoPorUid: 'ent1',
      estado: 'aprobado',
      deporteId: 'dep1',
      titulo: 'Ok',
    });
    await poner(['eventos', 'evNo'], {
      creadoPorUid: 'ent1',
      estado: 'rechazado',
      deporteId: 'dep1',
      titulo: 'No',
    });
  });

  it('el entrenador cancela y edita solo su solicitud pendiente', async () => {
    await assertSucceeds(updateDoc(doc(dbDe('ent1'), 'eventos', 'ev1'), {
      estado: 'cancelado',
      actualizadoEn: new Date(),
    }));
    await poner(['eventos', 'ev1'], { estado: 'pendiente' });
    await assertSucceeds(updateDoc(doc(dbDe('ent1'), 'eventos', 'ev1'), {
      titulo: 'Nuevo',
      fecha: '2026-12-02',
      actualizadoEn: new Date(),
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'eventos', 'ev2'), {
      estado: 'cancelado',
      actualizadoEn: new Date(),
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'eventos', 'evOk'), {
      estado: 'cancelado',
      actualizadoEn: new Date(),
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'eventos', 'evNo'), {
      estado: 'cancelado',
      actualizadoEn: new Date(),
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'eventos', 'ev1'), {
      deporteId: 'otro',
      actualizadoEn: new Date(),
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'eventos', 'ev1'), {
      creadoPorUid: 'ent2',
      actualizadoEn: new Date(),
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'eventos', 'ev1'), {
      estado: 'aprobado',
      actualizadoEn: new Date(),
    }));
    await assertSucceeds(updateDoc(doc(dbDe('admin1'), 'eventos', 'evOk'), {
      titulo: 'Admin',
    }));
  });

  it('identificadores, cédula y perfil del entrenador', async () => {
    const nuevo = entorno.authenticatedContext('nuevo').firestore();
    const batch = writeBatch(nuevo);
    batch.set(doc(nuevo, 'usuarios', 'nuevo'), {
      rol: 'estudiante',
      estado: 'activo',
      cedula: 'V-9',
      carnet: '999',
      solvente: false,
    });
    batch.set(doc(nuevo, 'identificadores', 'cedula_V-9'), {
      uid: 'nuevo',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    });
    batch.set(doc(nuevo, 'identificadores', 'carnet_999'), {
      uid: 'nuevo',
      tipo: 'carnet',
      creadoEn: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
    await assertFails(setDoc(doc(dbDe('est1'), 'identificadores', 'cedula_V-9'), {
      uid: 'est1',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(dbDe('est1'), 'identificadores', 'cedula_V-1'), {
      uid: 'est1',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(dbDe('est1'), 'identificadores', 'carnet_111'), {
      uid: 'est1',
      tipo: 'carnet',
      creadoEn: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('est1'), 'identificadores', 'cedula_V-1'), {
      uid: 'otro',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    }));
    await poner(['usuarios', 'estViejo'], {
      rol: 'estudiante',
      estado: 'activo',
      cedula: 'v-12345678',
      carnet: '20201111',
    });
    await assertSucceeds(setDoc(doc(dbDe('estViejo'), 'identificadores', 'cedula_V-12345678'), {
      uid: 'estViejo',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(dbDe('estViejo'), 'identificadores', 'carnet_20201111'), {
      uid: 'estViejo',
      tipo: 'carnet',
      creadoEn: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('estViejo'), 'identificadores', 'cedula_V-99999999'), {
      uid: 'estViejo',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    }));
    await poner(['identificadores', 'cedula_V-2'], {
      uid: 'est2',
      tipo: 'cedula',
      creadoEn: new Date(),
    });
    await assertFails(setDoc(doc(dbDe('est1'), 'identificadores', 'cedula_V-2'), {
      uid: 'est1',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    }));

    const propio = dbDe('est1');
    await assertFails(updateDoc(doc(propio, 'usuarios', 'est1'), { cedula: 'V-2' }));
    await assertFails(updateDoc(doc(propio, 'usuarios', 'est1'), { carnet: '2' }));
    await assertSucceeds(updateDoc(doc(propio, 'usuarios', 'est1'), { telefono: '04121111111' }));
    await assertFails(getDocs(collection(propio, 'identificadores')));
    await assertSucceeds(setDoc(doc(dbDe('admin1'), 'identificadores', 'cedula_V-8'), {
      uid: 'est1',
      tipo: 'cedula',
      creadoEn: new Date(),
    }));
    await assertSucceeds(deleteDoc(doc(dbDe('admin1'), 'identificadores', 'cedula_V-8')));
    await assertFails(updateDoc(doc(dbDe('admin1'), 'identificadores', 'cedula_V-8'), {
      uid: 'otro',
    }));

    await assertSucceeds(updateDoc(doc(dbDe('ent1'), 'entrenadores', 'ent1'), {
      biografia: 'Nueva',
      anosExperiencia: 3,
      certificaciones: ['A'],
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'entrenadores', 'ent1'), {
      nombre: 'Otro',
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'entrenadores', 'ent1'), {
      especialidad: 'Otra',
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'entrenadores', 'ent1'), {
      activo: false,
    }));
    await assertFails(updateDoc(doc(dbDe('ent1'), 'entrenadores', 'ent2'), {
      biografia: 'Ajena',
    }));
  });
});
