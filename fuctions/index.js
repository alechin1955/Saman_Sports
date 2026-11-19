const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const paypalClientId = defineSecret("PAYPAL_CLIENT_ID");
const paypalClientSecret = defineSecret("PAYPAL_CLIENT_SECRET");

const PAYPAL_API = "https://api-m.sandbox.paypal.com";

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
  const data = await response.json();
  return data.access_token;
}

exports.createPaypalOrder = onCall(
  { secrets: [paypalClientId, paypalClientSecret] },
  async (request) => {

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const { amount, currency = "USD" } = request.data;

    try {
      const accessToken = await generateAccessToken(
        paypalClientId.value(),
        paypalClientSecret.value()
      );

      const response = await fetch(`${PAYPAL_API}/v2/checkout/orders`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          intent: "CAPTURE",
          purchase_units: [
            {
              amount: {
                currency_code: currency,
                value: amount.toString(), // Ej: "15.00"
              },
            },
          ],
          application_context: {
            return_url: "https://tu-app.com/paypal-success",
            cancel_url: "https://tu-app.com/paypal-cancel",
            user_action: "PAY_NOW",
          },
        }),
      });

      const order = await response.json();
      const approveLink = order.links.find((link) => link.rel === "approve");

      return {
        orderId: order.id,
        approvalUrl: approveLink.href,
      };
    } catch (error) {
      throw new HttpsError("internal", "Error al crear la orden de PayPal", error);
    }
  }
);

exports.capturePaypalOrder = onCall(
  { secrets: [paypalClientId, paypalClientSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const { orderId } = request.data;

    try {
      const accessToken = await generateAccessToken(
        paypalClientId.value(),
        paypalClientSecret.value()
      );

      const response = await fetch(
        `${PAYPAL_API}/v2/checkout/orders/${orderId}/capture`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
        }
      );

      const captureData = await response.json();

      if (captureData.status === "COMPLETED") {
        return { success: true, details: captureData };
      } else {
        return { success: false, status: captureData.status };
      }
    } catch (error) {
      throw new HttpsError("internal", "Error al capturar el pago", error);
    }
  }
);