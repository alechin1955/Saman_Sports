const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const paypalClientSecret = defineSecret("PAYPAL_CLIENT_SECRET");

const PAYPAL_CLIENTID = "AY7pWu94lwi8JVlpfMOmd4js5krsyqScD480BA9L1BbJ_GXKQZJPng4rV0gEHgKEgPp5ufX5dJIAyE5a";
const PAYPAL_API = "https://api-m.sandbox.paypal.com";
const PAYPAL_CURRENCY = "USD";

function toCents(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? Math.round(amount * 100) : null;
}

async function generateAccessToken(clientId, clientSecret) {
  const auth = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
  const response = await fetch(`${PAYPAL_API}/v1/oauth2/token`, {
    method: "POST",
    body: "grant_type=client_credentials",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok || !data.access_token) {
    logger.error(
      `PayPal OAuth authentication failed: HTTP ${response.status}, ${data.error || "unknown error"}`,
    );
    throw new HttpsError(
      "failed-precondition",
      "PayPal no pudo autenticar la solicitud. Verifica los secrets de Functions.",
    );
  }
  return data.access_token;
}

async function paypalRequest(path, accessToken, options = {}) {
  const response = await fetch(`${PAYPAL_API}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      ...options.headers,
    },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    logger.error(
      `PayPal API request failed: ${path}, HTTP ${response.status}, ${data.name || "unknown error"}, ${data.details?.[0]?.issue || "no issue detail"}`,
    );
    throw new HttpsError("failed-precondition", "PayPal no pudo procesar la operación.");
  }
  return data;
}

function requireStudent(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }
}

exports.createPaypalOrder = onCall(
  { secrets: [paypalClientSecret] },
  async (request) => {
    requireStudent(request);

    const uid = request.auth.uid;
    const userRef = db.collection("usuarios").doc(uid);
    const [userSnapshot, configSnapshot] = await Promise.all([
      userRef.get(),
      db.collection("configuracion").doc("pagos").get(),
    ]);

    const user = userSnapshot.data() || {};
    if (!userSnapshot.exists || user.rol !== "estudiante" || user.estado === "inactivo") {
      throw new HttpsError("permission-denied", "Solo un estudiante activo puede pagar.");
    }
    if (!configSnapshot.exists) {
      throw new HttpsError("failed-precondition", "No hay un período de pago configurado.");
    }

    const config = configSnapshot.data() || {};
    const period = typeof config.periodo === "string" ? config.periodo.trim() : "";
    const amountCents = toCents(config.monto);
    if (!period || amountCents === null || amountCents <= 0) {
      throw new HttpsError("failed-precondition", "La configuración del pago no es válida.");
    }

    const pagosExistentes = await db
      .collection("pagos")
      .where("estudianteUid", "==", uid)
      .get();
    const yaRegistrado = pagosExistentes.docs.some((doc) => {
      const pago = doc.data();
      return pago.periodo === period && pago.estado !== "rechazado";
    });
    if (yaRegistrado) {
      throw new HttpsError("already-exists", "Ya existe un pago para este período.");
    }

    try {
      const accessToken = await generateAccessToken(
        PAYPAL_CLIENTID,
        paypalClientSecret.value(),
      );
      const order = await paypalRequest("/v2/checkout/orders", accessToken, {
        method: "POST",
        body: JSON.stringify({
          intent: "CAPTURE",
          purchase_units: [{
            amount: {
              currency_code: PAYPAL_CURRENCY,
              value: (amountCents / 100).toFixed(2),
            },
          }],
          application_context: {
            return_url: "https://saman-sports.web.app/",
            cancel_url: "https://saman-sports.web.app/",
            user_action: "PAY_NOW",
          },
        }),
      });
      const approvalUrl = order.links?.find((link) => link.rel === "approve")?.href;
      if (!order.id || !approvalUrl) {
        throw new HttpsError("internal", "PayPal no devolvió una orden válida.");
      }

      await db.collection("paypalOrders").doc(order.id).create({
        estudianteUid: uid,
        periodo: period,
        monto: amountCents / 100,
        moneda: PAYPAL_CURRENCY,
        estado: "pendiente",
        creadoEn: FieldValue.serverTimestamp(),
      });

      return { orderId: order.id, approvalUrl };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error(
        `createPaypalOrder failed for ${uid}: ${error?.message || String(error)}`,
      );
      throw new HttpsError("internal", "Error al crear la orden de PayPal.");
    }
  },
);

exports.capturePaypalOrder = onCall(
  { secrets: [paypalClientSecret] },
  async (request) => {
    requireStudent(request);
    const orderId = request.data?.orderId;
    if (typeof orderId !== "string" || !/^[A-Z0-9]+$/i.test(orderId)) {
      throw new HttpsError("invalid-argument", "El identificador de PayPal no es válido.");
    }

    const orderRef = db.collection("paypalOrders").doc(orderId);
    const paymentRef = db.collection("pagos").doc(orderId);
    const orderSnapshot = await orderRef.get();
    const orderRecord = orderSnapshot.data();
    if (!orderSnapshot.exists || orderRecord.estudianteUid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "La orden no pertenece a esta cuenta.");
    }

    const existingPayment = await paymentRef.get();
    if (existingPayment.exists && existingPayment.data()?.verificado === true) {
      return { success: true, orderId };
    }

    try {
      const accessToken = await generateAccessToken(
        PAYPAL_CLIENTID,
        paypalClientSecret.value(),
      );
      let order = await paypalRequest(
        `/v2/checkout/orders/${orderId}`,
        accessToken,
        { method: "GET" },
      );
      if (order.status !== "COMPLETED") {
        order = await paypalRequest(
          `/v2/checkout/orders/${orderId}/capture`,
          accessToken,
          { method: "POST" },
        );
      }

      const capture = order.purchase_units?.[0]?.payments?.captures?.find(
        (item) => item.status === "COMPLETED",
      );
      if (order.status !== "COMPLETED" || !capture) {
        throw new HttpsError("failed-precondition", "PayPal todavía no confirma el pago.");
      }

      const actualAmount = toCents(capture.amount?.value);
      if (
        capture.amount?.currency_code !== orderRecord.moneda ||
        actualAmount !== toCents(orderRecord.monto)
      ) {
        throw new HttpsError("failed-precondition", "El monto confirmado por PayPal no coincide.");
      }

      await db.runTransaction(async (transaction) => {
        const [currentOrder, currentPayment, currentConfig, userSnapshot] =
          await Promise.all([
            transaction.get(orderRef),
            transaction.get(paymentRef),
            transaction.get(db.collection("configuracion").doc("pagos")),
            transaction.get(db.collection("usuarios").doc(request.auth.uid)),
          ]);

        if (currentPayment.exists) {
          if (currentPayment.data()?.verificado === true) return;
          throw new HttpsError("already-exists", "Ya existe un registro para esta orden.");
        }
        if (
          !currentOrder.exists ||
          currentOrder.data()?.estudianteUid !== request.auth.uid
        ) {
          throw new HttpsError("permission-denied", "La orden no pertenece a esta cuenta.");
        }

        const period = currentOrder.data().periodo;
        const amount = currentOrder.data().monto;
        const currentConfigData = currentConfig.data() || {};
        const isCurrentPeriod =
          currentConfig.exists &&
          currentConfigData.periodo === period &&
          toCents(amount) >= toCents(currentConfigData.monto);
        const now = FieldValue.serverTimestamp();

        transaction.create(paymentRef, {
          estudianteUid: request.auth.uid,
          inscripcionId: "",
          monto: amount,
          periodo: period,
          paypalOrderId: orderId,
          idTransaccion: orderId,
          estado: "realizado",
          verificado: true,
          verificadoPor: "paypal",
          fecha: now,
          fechaPago: now,
          verificadoEn: now,
        });
        transaction.update(orderRef, {
          estado: "completado",
          completadoEn: now,
          paypalCaptureId: capture.id || "",
        });

        const student = userSnapshot.data() || {};
        if (
          isCurrentPeriod &&
          userSnapshot.exists &&
          student.rol === "estudiante" &&
          student.estado !== "inactivo"
        ) {
          transaction.update(userSnapshot.ref, { solvente: true });
        }

        const notificationRef = db.collection("notificaciones").doc();
        transaction.create(notificationRef, {
          destinatarioUid: request.auth.uid,
          destinatarioRol: "estudiante",
          origenUid: "",
          tipo: "pago_verificado",
          titulo: "Pago",
          mensaje: `Se verificó tu pago del período ${period}.`,
          leida: false,
          fecha: now,
          inscripcionId: "",
          pagoId: orderId,
          eventoId: "",
          ticketId: "",
          deporteId: "",
        });
      });

      return { success: true, orderId };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error(
        `capturePaypalOrder failed for order ${orderId}: ${error?.message || String(error)}`,
      );
      throw new HttpsError("internal", "Error al verificar el pago con PayPal.");
    }
  },
);