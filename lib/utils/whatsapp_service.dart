import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Necesario para colores
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Necesitamos exportar el QR a imagen

class WhatsAppService {

  /// Genera, descarga y comparte: Foto Paquete + Imagen QR + Texto Completo
  static Future<void> notificarVecino({
    required String photoUrl,
    required String neighborName,
    required String courier,
    required String tower,
    required String unit,
    required String packageId,
    required String receivedDate, // 🔥 Nuevo campo: Fecha de llegada
  }) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      List<XFile> filesToShare = [];

      // --- 1. DESCARGAR FOTO DEL PAQUETE ---
      final http.Response response = await http.get(Uri.parse(photoUrl));
      final File photoFile = File('${tempDir.path}/paquete_foto.jpg');
      await photoFile.writeAsBytes(response.bodyBytes);
      filesToShare.add(XFile(photoFile.path));

      // --- 2. GENERAR IMAGEN DEL CÓDIGO QR ---
      // Usamos el validador para crear el objeto QR matemático
      final qrValidationResult = QrValidator.validate(
        data: packageId,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.isValid) {
        final qrCode = qrValidationResult.qrCode;
        
        // Pintamos el QR en un lienzo invisible
        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          emptyColor: const Color(0xFFFFFFFF), // Fondo blanco
        );

        // Convertimos el lienzo a datos de imagen PNG (tamaño 800x800)
        final ByteData? picData = await painter.toImageData(800, format: ui.ImageByteFormat.png);
        
        if (picData != null) {
          final File qrFile = File('${tempDir.path}/paquete_qr.png');
          await qrFile.writeAsBytes(picData.buffer.asUint8List());
          filesToShare.add(XFile(qrFile.path));
        }
      }

      // --- 3. PREPARAR TEXTO DETALLADO ---
      final String mensaje = 
          "📦 *¡NUEVO PAQUETE EN PORTERÍA!*\n\n"
          "Hola *$neighborName*, ha llegado un envío para ti.\n\n"
          "🏢 *Apartamento:* $tower - $unit\n"
          "🚚 *Empresa:* $courier\n"
          "📅 *Llegada:* $receivedDate\n\n"
          "👇 *PARA RECLAMAR:* 👇\n"
          "Muestra el código QR adjunto a este mensaje o dicta el código: *$packageId*";

      // --- 4. ENVIAR TODO A WHATSAPP ---
      await Share.shareXFiles(
        filesToShare,
        text: mensaje, // WhatsApp pondrá esto como pie de foto o mensaje adjunto
      );

    } catch (e) {
      print("Error al compartir: $e");
      throw Exception("No se pudo compartir la información: $e");
    }
  }
}