/* Amplify Params - DO NOT EDIT
	ENV
	REGION
Amplify Params - DO NOT EDIT */

const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
// Inicializamos el cliente de correo en la región correcta
const ses = new SESClient({ region: process.env.REGION });

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */
exports.handler = async (event) => {
  console.log(`EVENT: ${JSON.stringify(event)}`);

  // 1. Obtener datos (Soporta invocación directa desde Flutter o vía API REST)
  // Si viene de API Gateway, los datos están en event.body (como string)
  // Si es invocación directa (SDK), están en event.arguments o event directo.
  let params;
  if (event.body) {
    try {
      params = JSON.parse(event.body);
    } catch (e) {
      params = event;
    }
  } else {
    params = event.arguments || event;
  }

  const { emails, subject, message, photoUrl, qrData, courier, tower, unit } = params;

  // Validación básica
  if (!emails || !Array.isArray(emails) || emails.length === 0) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Faltan destinatarios (emails)" }),
    };
  }

  // 2. Generar QR Visual para el correo (Usamos una API pública segura para renderizar)
  // Nota: En producción ultra-estricta, generaríamos el QR internamente con una librería,
  // pero para este paso usar quickchart.io o qrserver es estándar y fiable.
  const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(qrData)}`;

  // 3. Construir HTML (Diseño Corporativo)
  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Helvetica', sans-serif; background-color: #f4f4f4; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .header { background-color: #2c3e50; padding: 20px; text-align: center; color: white; }
        .content { padding: 30px; }
        .info-box { background-color: #e8f6f3; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 5px solid #1abc9c; }
        .footer { text-align: center; font-size: 12px; color: #7f8c8d; margin-top: 20px; padding: 20px; border-top: 1px solid #eee; }
        .btn { display: inline-block; background-color: #e74c3c; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px; font-weight: bold;}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>📦 ¡Ha llegado un Paquete!</h2>
        </div>
        <div class="content">
          <p>Hola vecino del <strong>${tower} - ${unit}</strong>,</p>
          <p>Te informamos que ha llegado un nuevo envío a la portería.</p>
          
          <div class="info-box">
            <p><strong>🚚 Empresa:</strong> ${courier}</p>
            <p><strong>📝 Nota:</strong> ${message}</p>
          </div>

          <div style="text-align: center;">
            <p>📸 <strong>Foto del Paquete:</strong></p>
            <img src="${photoUrl}" alt="Foto Paquete" style="max-width: 100%; border-radius: 8px; border: 1px solid #ddd; margin-bottom: 20px;">
            
            <hr style="border: 0; border-top: 1px dashed #ddd; margin: 20px 0;">
            
            <p>🔐 <strong>Tu Código de Retiro:</strong></p>
            <img src="${qrImageUrl}" alt="QR Code" style="width: 150px; height: 150px;">
            <p style="font-size: 24px; font-weight: bold; letter-spacing: 3px; margin: 5px 0;">${qrData}</p>
            <p style="font-size: 12px; color: #999;">Muestra este código al portero</p>
          </div>
        </div>
        <div class="footer">
          <p>Sistema de Portería Inteligente</p>
          <p>Por favor no respondas a este mensaje.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  // 4. Configurar envío SES
  const command = new SendEmailCommand({
    Destination: {
      ToAddresses: emails, // AWS SES en Sandbox solo permite enviar a emails verificados
    },
    Message: {
      Body: {
        Html: { Data: htmlBody },
        Text: { Data: `Tienes un paquete de ${courier}. Código: ${qrData}` },
      },
      Subject: { Data: subject },
    },
    // Este correo no necesitas crearlo en ningún lado, AWS lo "simula" por ti.
    Source: "notificaciones@holaveciapp.com",
  });

  try {
    await ses.send(command);
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Correos enviados exitosamente" }),
    };
  } catch (error) {
    console.error("Error enviando SES:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};