import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // Necesario para QrPainter
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ModelProvider.dart';

class ResidentPackageDetailScreen extends StatefulWidget {
  final Package package;

  const ResidentPackageDetailScreen({super.key, required this.package});

  @override
  State<ResidentPackageDetailScreen> createState() => _ResidentPackageDetailScreenState();
}

class _ResidentPackageDetailScreenState extends State<ResidentPackageDetailScreen> {
  
  String? _cachedImageUrl;
  bool _isSharing = false;

  Future<String> _getImageUrl(String key) async {
    if (_cachedImageUrl != null) return _cachedImageUrl!;
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(key),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(validateObjectExistence: true, expiresIn: Duration(minutes: 60)),
        ),
      ).result;
      _cachedImageUrl = result.url.toString();
      return _cachedImageUrl!;
    } catch (e) {
      return "";
    }
  }

  // 👇 LÓGICA DE COMPARTIR QR + TEXTO LIMPIO
  Future<void> _sharePackageInfo() async {
    setState(() => _isSharing = true);
    try {
      final pkg = widget.package;

      // 1. Generar la imagen del QR en memoria
      final qrValidationResult = QrValidator.validate(
        data: pkg.id,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF0F172A),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        // Renderizamos a PNG (800x800 para buena calidad)
        final picData = await painter.toImageData(800.0); 
        
        if (picData != null) {
          // 2. Guardar temporalmente
          final tempDir = await getTemporaryDirectory();
          final path = '${tempDir.path}/qr_entrega.png';
          final file = await File(path).create();
          await file.writeAsBytes(picData.buffer.asUint8List());

          // 3. Texto exacto solicitado
          final String message = """
                                  👋 Hola, ¿me ayudas a recoger mi paquete?

                                  📦 Empresa: ${pkg.courier}
                                  🏢 Apto: ${pkg.recipient?.unit ?? '?'} - ${pkg.recipient?.tower ?? '?'}
                                                                                                            """;

// 5. CORRECCIÓN: Agregar mimeType explícito y subject
          await Share.shareXFiles(
            [XFile(path, mimeType: 'image/png')], // 👈 Especificamos que es PNG
            text: message,
            subject: 'Recoger Paquete', // Ayuda en correos/otros
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final date = DateTime.parse(pkg.receivedAt.toString()).toLocal();
    final dateFormatted = DateFormat('dd MMM, hh:mm a').format(date);
    
    final bool isPending = pkg.status == PackageStatus.IN_WAREHOUSE;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Paquete"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      
      // BOTÓN FLOTANTE VERDE
      floatingActionButton: isPending ? FloatingActionButton.extended(
        onPressed: _isSharing ? null : _sharePackageInfo,
        backgroundColor: Colors.green, 
        icon: _isSharing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.share, color: Colors.white),
        label: Text(_isSharing ? "GENERANDO..." : "ENVIAR QR A AMIGO", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            // FOTO
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: pkg.photoKey != null
                  ? FutureBuilder<String>(
                      future: _getImageUrl(pkg.photoKey!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Image.network(snapshot.data!, fit: BoxFit.cover);
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // CARD INFO
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: Column(
                children: [
                  
                  if (isPending) ...[
                    const Text("Muestra este código en portería", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15),
                    QrImageView(
                      data: pkg.id,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    const Text("💡 Tip: Usa el botón verde para enviar este QR por WhatsApp a quien vaya a recoger tu paquete.", 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 100),
                    const SizedBox(height: 10),
                    const Text(
                      "ENTREGADO",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    if (pkg.deliveredAt != null)
                       Text(
                        "El ${DateFormat('dd MMM, hh:mm a').format(DateTime.parse(pkg.deliveredAt.toString()).toLocal())}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  Text(pkg.courier, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(dateFormatted, style: const TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 15),
                  
                  Chip(
                    label: Text(isPending ? "En Portería" : "Entregado"),
                    backgroundColor: isPending ? Colors.orange[100] : Colors.green[100],
                    labelStyle: TextStyle(color: isPending ? Colors.orange[900] : Colors.green[900], fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}