/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */
exports.handler = async (event, context) => {
  // Confirmar automáticamente al usuario
  event.response.autoConfirmUser = true;

  // Verificar el email automáticamente (para evitar líos con Cognito)
  if (event.request.userAttributes.hasOwnProperty("email")) {
    event.response.autoVerifyEmail = true;
  }

  // Devolver el evento a Cognito
  return event;
};