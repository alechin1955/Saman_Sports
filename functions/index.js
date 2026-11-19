const { onCall, HttpsError } = require("firebase-functions/v2/https");


const PAYPAL_CLIENT_ID = "AY7pWu94lwi8JVlpfMOmd4js5krsyqScD480BA9L1BbJ_GXKQZJPng4rV0gEHgKEgPp5ufX5dJIAyE5a";
const PAYPAL_CLIENT_SECRET = "EFVc0niPgXCPBs1Jr_uIET2a0ACSbl33NZ1F8_pi6A7_xGl24Gu3baLIL7FPsGI1rOXrkP4SQScXS5uL";

const PAYPAL_API = "https://api-m.sandbox.paypal.com";

async function generateAccessToken() {
  const auth = Buffer.from(`${PAYPAL_CLIENT_ID}:${PAYPAL_CLIENT_SECRET}`).toString("base64");
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


exports.createPaypalOrder = onCall(async (request) => {
  const { amount, currency = "USD" } = request.data;

  try {
    const accessToken = await generateAccessToken();

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
              value: amount.toString(),
            },
          },
        ],
        application_context: {
          return_url: "localhost:57569/paypal-success",
          cancel_url: "localhost:57569/paypal-cancel",
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
});

exports.capturePaypalOrder = onCall(async (request) => {
  const { orderId } = request.data;

  try {
    const accessToken = await generateAccessToken();

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
});