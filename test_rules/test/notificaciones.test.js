const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
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

async function poner(ruta, datos) {
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    await setDoc(doc(contexto.firestore(), ...ruta), datos, { merge: true });
  });
}

function aviso(extra) {
  return {
    destinatarioUid: 'est1',
    destinatarioRol: 'estudiante',
    origenUid: 'est1',
    tipo: 'inscripcion_creada',
    titulo: 'Inscripción',
    mensaje: 'Pendiente',
    leida: false,
    fecha: serverTimestamp(),
    ...extra,
  };
}

describe('notificaciones y eventos', () => {
  before(async () => {
    entorno = await initializeTestEnvironment({
      projectId: 'demo-saman-notificaciones',
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
    await poner(['usuarios', 'est1'], { rol: 'estudiante', estado: 'activo', solvente: true, nombre: 'Ana' });
    await poner(['usuarios', 'est2'], { rol: 'estudiante', estado: 'activo', solvente: true });
    await poner(['usuarios', 'est3'], { rol: 'estudiante', estado: 'activo', solvente: true });
    await poner(['usuarios', 'ent1'], { rol: 'entrenador', estado: 'activo' });
    await poner(['usuarios', 'ent2'], { rol: 'entrenador', estado: 'activo' });
    await poner(['usuarios', 'admin1'], { rol: 'administrador', estado: 'activo' });
    await poner(['deportes', 'dep1'], {
      nombre: 'Fútbol',
      activo: true,
      entrenadorUid: 'ent1',
      cupos: 10,
      inscritos: 1,
    });
    await poner(['inscripciones', 'est1_dep1'], {
      estudianteUid: 'est1',
      deporteId: 'dep1',
      estado: 'pendiente',
      deporteNombre: 'Fútbol',
    });
    await poner(['inscripciones', 'est2_dep1'], {
      estudianteUid: 'est2',
      deporteId: 'dep1',
      estado: 'cancelada',
    });
    await poner(['eventos', 'evOk'], {
      estado: 'aprobado',
      deporteId: 'dep1',
      titulo: 'Torneo',
      fecha: '2026-12-01',
      creadoPorUid: 'admin1',
    });
    await poner(['eventos', 'evPend'], {
      estado: 'pendiente',
      deporteId: 'dep1',
      titulo: 'Borrador',
      fecha: '2026-12-02',
      creadoPorUid: 'ent1',
    });
    await poner(['eventos', 'evGen'], {
      estado: 'aprobado',
      titulo: 'General',
      fecha: '2026-12-03',
      creadoPorUid: 'admin1',
    });
    await poner(['eventosPublicos', 'evOk'], {
      titulo: 'Torneo',
      tipo: 'evento',
      deporteId: 'dep1',
      deporteNombre: 'Fútbol',
      canchaNombre: 'A',
      fecha: '2026-12-01',
      horaInicio: 480,
      horaFin: 540,
      descripcion: '',
      actualizadoEn: new Date(),
    });
  });

  it('estudiante y entrenador leen eventos aprobados', async () => {
    await assertSucceeds(getDoc(doc(dbDe('est1'), 'eventos', 'evOk')));
    await assertSucceeds(getDocs(query(
      collection(dbDe('est1'), 'eventos'),
      where('estado', '==', 'aprobado'),
    )));
    await assertFails(getDoc(doc(dbDe('est1'), 'eventos', 'evPend')));
    await assertSucceeds(getDocs(query(
      collection(dbDe('ent1'), 'eventos'),
      where('estado', '==', 'aprobado'),
    )));
  });

  it('eventosPublicos es de lectura pública y escritura solo del admin', async () => {
    const anon = entorno.unauthenticatedContext().firestore();
    await assertSucceeds(getDocs(query(
      collection(anon, 'eventosPublicos'),
      where('fecha', '>=', '2026-01-01'),
      orderBy('fecha'),
    )));
    await assertFails(setDoc(doc(dbDe('est1'), 'eventosPublicos', 'nuevo'), {
      titulo: 'X',
      tipo: 'evento',
      deporteId: '',
      deporteNombre: '',
      canchaNombre: '',
      fecha: '2026-12-01',
      horaInicio: 1,
      horaFin: 2,
      descripcion: '',
      actualizadoEn: new Date(),
    }));
    await assertFails(setDoc(doc(dbDe('admin1'), 'eventosPublicos', 'nuevo'), {
      titulo: 'X',
      tipo: 'evento',
      deporteId: '',
      deporteNombre: '',
      canchaNombre: '',
      fecha: '2026-12-01',
      horaInicio: 1,
      horaFin: 2,
      descripcion: '',
      actualizadoEn: new Date(),
      creadoPorUid: 'admin1',
    }));
  });

  it('solo el inscrito confirma o rechaza su participación', async () => {
    const propio = doc(dbDe('est1'), 'eventos', 'evOk', 'participantes', 'est1');
    await assertSucceeds(setDoc(propio, {
      estudianteUid: 'est1',
      estado: 'confirmado',
      fecha: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(propio, {
      estudianteUid: 'est1',
      estado: 'rechazado',
      fecha: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('est3'), 'eventos', 'evOk', 'participantes', 'est3'), {
      estudianteUid: 'est3',
      estado: 'confirmado',
      fecha: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('est2'), 'eventos', 'evOk', 'participantes', 'est2'), {
      estudianteUid: 'est2',
      estado: 'confirmado',
      fecha: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('est1'), 'eventos', 'evOk', 'participantes', 'est3'), {
      estudianteUid: 'est3',
      estado: 'confirmado',
      fecha: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('est1'), 'eventos', 'evPend', 'participantes', 'est1'), {
      estudianteUid: 'est1',
      estado: 'confirmado',
      fecha: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(dbDe('est1'), 'eventos', 'evGen', 'participantes', 'est1'), {
      estudianteUid: 'est1',
      estado: 'confirmado',
      fecha: serverTimestamp(),
    }));
    await assertFails(setDoc(propio, {
      estudianteUid: 'est1',
      estado: 'confirmado',
      fecha: serverTimestamp(),
      extra: true,
    }));
    await assertSucceeds(getDocs(collection(dbDe('ent1'), 'eventos', 'evOk', 'participantes')));
    await assertFails(getDocs(collection(dbDe('ent2'), 'eventos', 'evOk', 'participantes')));
  });

  it('el estudiante avisa su inscripción solo junto con la escritura', async () => {
    const db = dbDe('est3');
    const batch = writeBatch(db);
    batch.update(doc(db, 'deportes', 'dep1'), { inscritos: 2 });
    batch.set(doc(db, 'inscripciones', 'est3_dep1'), {
      estudianteUid: 'est3',
      deporteId: 'dep1',
      deporteNombre: 'Fútbol',
      estado: 'pendiente',
      fecha: serverTimestamp(),
    });
    batch.set(doc(db, 'notificaciones', 'propia'), aviso({
      destinatarioUid: 'est3',
      origenUid: 'est3',
      tipo: 'inscripcion_creada',
      inscripcionId: 'est3_dep1',
      deporteId: 'dep1',
    }));
    batch.set(doc(db, 'notificaciones', 'admin'), aviso({
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'est3',
      tipo: 'inscripcion_pendiente',
      inscripcionId: 'est3_dep1',
      deporteId: 'dep1',
    }));
    await assertSucceeds(batch.commit());

    const cancela = writeBatch(db);
    cancela.update(doc(db, 'inscripciones', 'est3_dep1'), { estado: 'cancelada' });
    cancela.update(doc(db, 'deportes', 'dep1'), { inscritos: 1 });
    cancela.set(doc(db, 'notificaciones', 'cancel'), aviso({
      destinatarioUid: 'est3',
      origenUid: 'est3',
      tipo: 'inscripcion_cancelada',
      inscripcionId: 'est3_dep1',
      deporteId: 'dep1',
    }));
    await assertSucceeds(cancela.commit());

    await assertFails(setDoc(doc(dbDe('est1'), 'notificaciones', 'suelto'), aviso({
      tipo: 'inscripcion_creada',
      inscripcionId: 'est1_dep1',
    })));
    await assertFails(setDoc(doc(dbDe('est1'), 'notificaciones', 'ajeno'), aviso({
      destinatarioUid: 'est2',
      tipo: 'inscripcion_creada',
      inscripcionId: 'est1_dep1',
    })));
    await assertFails(setDoc(doc(dbDe('est1'), 'notificaciones', 'extra'), {
      ...aviso({ tipo: 'inscripcion_creada', inscripcionId: 'est1_dep1' }),
      periodo: 'x',
    }));
    await assertFails(setDoc(doc(dbDe('est1'), 'notificaciones', 'leida'), aviso({
      tipo: 'inscripcion_creada',
      inscripcionId: 'est1_dep1',
      leida: true,
    })));
  });

  it('el admin recibe solicitudes, pagos, tickets y registros', async () => {
    const ent = dbDe('ent1');
    const evento = writeBatch(ent);
    evento.set(doc(ent, 'eventos', 'sol1'), {
      creadoPorUid: 'ent1',
      estado: 'pendiente',
      deporteId: 'dep1',
      titulo: 'Solicitud',
      fecha: '2026-12-20',
      horaInicio: 480,
      horaFin: 540,
      capacidad: 10,
      canchaId: 'c1',
      canchaNombre: 'A',
      descripcion: '',
      ubicacion: '',
    });
    evento.set(doc(ent, 'notificaciones', 'sol'), aviso({
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'ent1',
      tipo: 'solicitud_evento',
      eventoId: 'sol1',
      deporteId: 'dep1',
    }));
    await assertSucceeds(evento.commit());

    const pago = writeBatch(dbDe('est1'));
    pago.set(doc(dbDe('est1'), 'pagos', 'p1'), {
      estudianteUid: 'est1',
      monto: 10,
      periodo: '2026-1',
      estado: 'pendiente',
      verificado: false,
      fecha: serverTimestamp(),
    });
    pago.set(doc(dbDe('est1'), 'notificaciones', 'pago'), aviso({
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'est1',
      tipo: 'pago_enviado',
      pagoId: 'p1',
    }));
    await assertSucceeds(pago.commit());

    const ticket = writeBatch(dbDe('est1'));
    ticket.set(doc(dbDe('est1'), 'tickets', 't1'), {
      autorUid: 'est1',
      autorRol: 'estudiante',
      estado: 'abierto',
      asunto: 'Ayuda',
      categoria: 'otro',
      descripcion: 'Detalle suficiente',
      respuesta: '',
      resueltoEn: null,
      fecha: serverTimestamp(),
    });
    ticket.set(doc(dbDe('est1'), 'notificaciones', 'ticket'), aviso({
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'est1',
      tipo: 'ticket_nuevo',
      ticketId: 't1',
    }));
    await assertSucceeds(ticket.commit());

    const registro = writeBatch(dbDe('estNuevo'));
    registro.set(doc(dbDe('estNuevo'), 'usuarios', 'estNuevo'), {
      rol: 'estudiante',
      estado: 'activo',
      solvente: false,
      cedula: 'V-9',
      carnet: '999',
    });
    registro.set(doc(dbDe('estNuevo'), 'identificadores', 'cedula_V-9'), {
      uid: 'estNuevo',
      tipo: 'cedula',
      creadoEn: serverTimestamp(),
    });
    registro.set(doc(dbDe('estNuevo'), 'identificadores', 'carnet_999'), {
      uid: 'estNuevo',
      tipo: 'carnet',
      creadoEn: serverTimestamp(),
    });
    registro.set(doc(dbDe('estNuevo'), 'notificaciones', 'reg'), aviso({
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'estNuevo',
      tipo: 'registro_estudiante',
    }));
    await assertSucceeds(registro.commit());

    await assertFails(setDoc(doc(dbDe('est1'), 'notificaciones', 'ajenoTicket'), aviso({
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'est1',
      tipo: 'ticket_nuevo',
      ticketId: 't1',
    })));
  });

  it('la bandeja del admin no la lee un estudiante', async () => {
    await poner(['notificaciones', 'bandeja'], {
      destinatarioUid: '',
      destinatarioRol: 'administrador',
      origenUid: 'est1',
      tipo: 'inscripcion_pendiente',
      titulo: 'A',
      mensaje: 'B',
      leida: false,
      fecha: new Date(),
    });
    await assertSucceeds(getDocs(query(
      collection(dbDe('admin1'), 'notificaciones'),
      where('destinatarioRol', '==', 'administrador'),
    )));
    await assertSucceeds(updateDoc(doc(dbDe('admin1'), 'notificaciones', 'bandeja'), {
      leida: true,
    }));
    await assertFails(getDocs(query(
      collection(dbDe('est1'), 'notificaciones'),
      where('destinatarioRol', '==', 'administrador'),
    )));
    await assertFails(updateDoc(doc(dbDe('admin1'), 'notificaciones', 'bandeja'), {
      titulo: 'Otro',
    }));
  });
});
