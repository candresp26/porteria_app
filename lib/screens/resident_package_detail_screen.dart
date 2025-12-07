import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:qr_flutter/qr_flutter.dart'; // 👈 IMPORTANTE
import 'package:intl/intl.dart';
import '../models/ModelProvider.dart';

class ResidentPackageDetailScreen extends StatefulWidget {
  final Package package;

  const ResidentPackageDetailScreen({super.key, required this.package});

  @override
  State<ResidentPackageDetailScreen> createState() => _ResidentPackageDetailScreenState();
}

class _ResidentPackageDetailScreenState extends State<ResidentPackageDetailScreen> {
  
  // Helper para traer la imagen desde S3
  Future<String> _getImageUrl(String key) async {
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(key),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(validateObjectExistence: true, expiresIn: Duration(minutes: 60)),
        ),
      ).result;
      return result.url.toString();
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final date = DateTime.parse(pkg.receivedAt.toString()).toLocal();
    final dateFormatted = DateFormat('dd MMM, hh:mm a').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu Paquete"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. FOTO DEL PAQUETE (Visual)
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

            // 2. CÓDIGO QR (La Llave de entrega)
            Text("Muestra este código en portería", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: pkg.id, // 🔑 EL QR CONTIENE EL ID DEL PAQUETE
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.indigo),
                  ),
                  const SizedBox(height: 10),
                  Text(pkg.courier, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(dateFormatted, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(pkg.status == PackageStatus.IN_WAREHOUSE ? "En Portería" : "Entregado"),
                    backgroundColor: pkg.status == PackageStatus.IN_WAREHOUSE ? Colors.orange[100] : Colors.green[100],
                    labelStyle: TextStyle(color: pkg.status == PackageStatus.IN_WAREHOUSE ? Colors.orange[900] : Colors.green[900]),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "💡 Tip: El portero escaneará este código para confirmar la entrega y que el paquete es tuyo.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}