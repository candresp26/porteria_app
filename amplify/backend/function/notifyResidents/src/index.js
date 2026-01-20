/* Amplify Params - DO NOT EDIT
   ENV
   REGION
Amplify Params - DO NOT EDIT */

const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const { DynamoDBClient, GetItemCommand, ScanCommand } = require("@aws-sdk/client-dynamodb");

const ses = new SESClient({ region: process.env.REGION });
const docClient = new DynamoDBClient({ region: process.env.REGION });

// ⚠️ Asegúrate que este nombre de tabla sea el correcto (revisa tu DynamoDB si tienes dudas)
const USER_TABLE_NAME = process.env.API_PORTERIAAPP_USERTABLE_NAME || "User-edonjj33pffyjomipwiwlg2qui-dev"; 

exports.handler = async (event) => {
  console.log("EVENTO:", JSON.stringify(event));

  for (const record of event.Records) {
    try {
      // CASO 1: LLEGADA (INSERT)
      if (record.eventName === 'INSERT') {
        const newImage = record.dynamodb.NewImage;
        await procesarLlegada(newImage);
      } 
      
      // CASO 2: ENTREGA (MODIFY)
      else if (record.eventName === 'MODIFY') {
        const newImage = record.dynamodb.NewImage;
        const oldImage = record.dynamodb.OldImage;

        const newStatus = newImage.status ? newImage.status.S : null;
        const oldStatus = oldImage.status ? oldImage.status.S : null;

        if (newStatus === 'DELIVERED' && oldStatus === 'IN_WAREHOUSE') {
          console.log(`📦 Entrega detectada ID: ${newImage.id.S}`);
          await procesarEntrega(newImage);
        }
      }

    } catch (error) {
      console.error("🔥 Error Global en Lambda:", error);
    }
  }
  return { statusCode: 200, body: 'Procesado' };
};

// ============================================================================
// LÓGICA DE LLEGADA
// ============================================================================
async function procesarLlegada(newImage) {
  const recipientID = newImage.recipientID ? newImage.recipientID.S : null;
  const courier = newImage.courier ? newImage.courier.S : 'Mensajería';
  const qrData = newImage.id ? newImage.id.S : '0000';
  const photoKey = newImage.photoKey ? newImage.photoKey.S : null;
  const receivedBy = newImage.receivedBy ? newImage.receivedBy.S : 'Portería';
  const receivedAtRaw = newImage.receivedAt ? newImage.receivedAt.S : new Date().toISOString();
  const formattedDate = formatDateCO(receivedAtRaw);
  const photoUrl = photoKey ? photoKey : null; 

  if (!recipientID) return;

  // 1. Buscamos al usuario principal para saber Torre y Apto
  const mainUser = await buscarUsuario(recipientID);
  if (!mainUser) return;

  // 2. Buscamos TODOS los correos de ese apartamento
  console.log(`🔍 Buscando vecinos de Torre ${mainUser.tower} - Apto ${mainUser.unit}...`);
  const listaEmails = await buscarCorreosVecinos(mainUser.tower, mainUser.unit);
  
  if (listaEmails.length === 0) {
      console.log("⚠️ No se encontraron emails para notificar.");
      return;
  }

  console.log(`✅ Enviando correo LLEGADA a grupo familiar: ${JSON.stringify(listaEmails)}`);
  
  // 3. Enviamos UN solo correo a todos
  await sendEmailUrbian_Llegada(
    listaEmails, // Array de correos
    mainUser.tower, 
    mainUser.unit, 
    courier, 
    qrData, 
    photoUrl, 
    mainUser.name, // Nombre del titular (o puedes poner "Familia")
    formattedDate,
    receivedBy
  );
}

// ============================================================================
// LÓGICA DE ENTREGA
// ============================================================================
async function procesarEntrega(newImage) {
  const recipientID = newImage.recipientID ? newImage.recipientID.S : null;
  const courier = newImage.courier ? newImage.courier.S : 'Mensajería';
  const deliveredBy = newImage.deliveredBy ? newImage.deliveredBy.S : 'Portería';
  const deliveredAtRaw = newImage.deliveredAt ? newImage.deliveredAt.S : new Date().toISOString();
  const formattedDate = formatDateCO(deliveredAtRaw);

  if (!recipientID) return;

  const mainUser = await buscarUsuario(recipientID);
  if (!mainUser) return;

  // 1. También notificamos a todos en la entrega (opcional, pero recomendado)
  const listaEmails = await buscarCorreosVecinos(mainUser.tower, mainUser.unit);

  if (listaEmails.length === 0) return;

  console.log(`✅ Enviando correo ENTREGA a grupo familiar: ${JSON.stringify(listaEmails)}`);

  await sendEmailUrbian_Entrega(
    listaEmails, 
    mainUser.name, 
    courier, 
    formattedDate, 
    mainUser.unit,
    deliveredBy 
  );
}

// ============================================================================
// HELPERS DE BÚSQUEDA (DYNAMODB)
// ============================================================================

async function buscarUsuario(userId) {
  const userParams = {
    TableName: USER_TABLE_NAME,
    Key: { id: { S: userId } }
  };
  const userResult = await docClient.send(new GetItemCommand(userParams));
  
  if (!userResult.Item) return null;
  const u = userResult.Item;
  return {
    email: u.email ? u.email.S : null,
    unit: u.unit ? u.unit.S : '',
    tower: u.tower ? u.tower.S : '',
    name: u.name ? u.name.S : 'Vecino'
  };
}

// 👇 NUEVA FUNCIÓN: Busca a todos los que vivan en la misma Torre y Unidad
async function buscarCorreosVecinos(tower, unit) {
    if (!tower || !unit) return [];

    try {
        // Hacemos un SCAN filtrando por Torre y Unidad
        // Nota: Para bases de datos gigantes esto no es óptimo, pero para edificios (mil usuarios) es perfecto y rápido.
        const command = new ScanCommand({
            TableName: USER_TABLE_NAME,
            FilterExpression: "#tw = :towerVal AND #un = :unitVal",
            ExpressionAttributeNames: {
                "#tw": "tower",
                "#un": "unit",
                "#em": "email" // Solo queremos traer el email si existe
            },
            ExpressionAttributeValues: {
                ":towerVal": { S: tower },
                ":unitVal": { S: unit }
            },
            ProjectionExpression: "#em" // Solo traemos el campo email para ahorrar datos
        });

        const response = await docClient.send(command);
        
        // Filtramos: Que tenga email y extraemos el string
        const emails = response.Items
            .filter(item => item.email && item.email.S)
            .map(item => item.email.S);

        // Eliminamos duplicados por si acaso
        return [...new Set(emails)];

    } catch (e) {
        console.error("Error buscando vecinos:", e);
        return [];
    }
}

function formatDateCO(isoString) {
  try {
    const date = new Date(isoString);
    return date.toLocaleString("es-CO", { 
      timeZone: "America/Bogota",
      day: "2-digit", month: "short", year: "numeric", 
      hour: "2-digit", minute: "2-digit", hour12: true
    });
  } catch (e) { return isoString; }
}

// ============================================================================
// PLANTILLAS DE CORREO
// ============================================================================

// LLEGADA
async function sendEmailUrbian_Llegada(emails, tower, unit, courier, qrData, photoUrl, userName, dateStr, receivedBy) {
  const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(qrData)}`;
  
  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"></head>
    <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden;">
        <div style="background-color: #0f172a; padding: 20px; text-align: center;">
          <h1 style="color: #2dd4bf; margin: 0;">URBIAN</h1>
        </div>
        <div style="padding: 30px;">
          <h2 style="color: #0f172a; margin-top: 0;">¡Hola Vecinos! 📦</h2>
          <p>Llegó un paquete para <strong>${tower || ''} ${unit}</strong> (A nombre de: ${userName}).</p>
          
          <div style="background-color: #f8fafc; border-left: 5px solid #2dd4bf; padding: 15px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>🚚 Empresa:</strong> ${courier}</p>
            <p style="margin: 5px 0;"><strong>📅 Recibido:</strong> ${dateStr}</p> 
            <p style="margin: 5px 0;"><strong>👮 Recibido por:</strong> ${receivedBy}</p> 
          </div>

          <div style="text-align: center; border: 1px dashed #cbd5e1; padding: 15px; border-radius: 8px;">
            <p style="margin:0 0 10px 0; font-weight:bold;">Código de retiro:</p>
            <img src="${qrImageUrl}" alt="QR" style="width: 150px; height: 150px;">
          </div>
          
          <center style="margin-top: 20px;">
            <a href="urbian://paquetes" style="background-color: #0f172a; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;">Abrir App</a>
          </center>
        </div>
      </div>
    </body>
    </html>
  `;

  await ses.send(new SendEmailCommand({
    Destination: { ToAddresses: emails }, // 👈 AQUÍ SE ENVÍA A TODOS
    Message: {
      Body: { Html: { Data: htmlBody }, Text: { Data: `Nuevo paquete para ${unit}` } },
      Subject: { Data: `📦 ¡Nuevo paquete en ${unit}! - Urbian` },
    },
    Source: "info@holaveciapp.com", 
  }));
}

// ENTREGA
async function sendEmailUrbian_Entrega(emails, userName, courier, dateStr, unit, deliveredBy) {
  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"></head>
    <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden;">
        <div style="background-color: #0f172a; padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">URBIAN</h1>
        </div>
        <div style="padding: 30px;">
          <div style="text-align: center; color: #15803d; font-size: 40px;">✓</div>
          <h2 style="text-align: center; color: #15803d; margin-top: 0;">Entrega Exitosa</h2>
          
          <p>El paquete de <strong>${userName}</strong> ha sido retirado.</p>
          
          <div style="background-color: #f0fdf4; border: 1px solid #bbf7d0; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>📦 Empresa:</strong> ${courier}</p>
            <p style="margin: 5px 0;"><strong>📅 Fecha:</strong> ${dateStr}</p>
            <p style="margin: 5px 0;"><strong>👮 Entregado por:</strong> ${deliveredBy}</p>
            <p style="margin: 5px 0;"><strong>✅ Estado:</strong> FINALIZADO</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;

  await ses.send(new SendEmailCommand({
    Destination: { ToAddresses: emails }, // 👈 AQUÍ SE ENVÍA A TODOS
    Message: {
      Body: { Html: { Data: htmlBody }, Text: { Data: `Paquete entregado.` } },
      Subject: { Data: "✅ Paquete Entregado - Urbian" },
    },
    Source: "info@holaveciapp.com", 
  }));
}