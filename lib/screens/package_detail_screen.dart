import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:intl/intl.dart';
import '../models/ModelProvider.dart';

import '../utils/whatsapp_service.dart';

// 👇👇👇 ESTE IMPORT ES VITAL PARA QUE SALGA LA FIRMA 👇👇👇
import '../widgets/signature_pad.dart'; 

class PackageDetailScreen extends StatefulWidget {
  final Package package;
  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _isDelivering = false;

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

  // A. LÓGICA: ABRE EL PAD DE FIRMA
  Future<void> _processDeliveryWithSignature(BuildContext context) async {
    // Abre el diálogo importado de signature_pad.dart
    final Uint8List? signatureBytes = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignaturePad(), // 👈 Sin const
    );

    if (signatureBytes == null) return; // Si canceló o cerró sin firmar

    // Si firmó, procedemos a entregar
    _executeDelivery(DeliveryMethod.MANUAL_WITH_SIGNATURE, signatureBytes);
  }

  // B. LÓGICA: EMERGENCIA (SIN FIRMA)
  void _confirmNoSignature(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Entregar SIN firma?", style: TextStyle(color: Colors.red)),
        content: const Text("⚠️ Esta acción quedará marcada en rojo en el historial para revisión administrativa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              // Enviamos null en la firma
              _executeDelivery(DeliveryMethod.MANUAL_NO_SIGNATURE, null);
            },
            child: const Text("Confirmar Entrega"),
          ),
        ],
      ),
    );
  }

  // C. FUNCIÓN CENTRALIZADA DE ENTREGA
  Future<void> _executeDelivery(DeliveryMethod method, Uint8List? signatureData) async {
    setState(() => _isDelivering = true);
    try {
      String? sigKey;
      
      // 1. Subir Firma a S3 (si existe)
      if (signatureData != null) {
        sigKey = "signatures/${widget.package.id}.png";
        
        await Amplify.Storage.uploadData(
          data: StorageDataPayload.bytes(signatureData),
          path: StoragePath.fromString(sigKey),
           options: const StorageUploadDataOptions(
            pluginOptions: S3UploadDataPluginOptions(getProperties: true)
          )
        ).result;
      }

      // 2. Actualizar Base de Datos
      final updatedPkg = widget.package.copyWith(
        status: PackageStatus.DELIVERED,
        deliveryMethod: method,
        signatureKey: sigKey
      );

      final request = ModelMutations.update(updatedPkg, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        throw Exception(response.errors.first.message);
      }

      // 3. Éxito
      if (mounted) {
        Navigator.pop(context); // Volver a la lista
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Paquete entregado correctamente"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isDelivering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final date = DateTime.parse(pkg.receivedAt.toString()).toLocal();
    final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(date);
    final unitInfo = "Apto ${pkg.recipient?.apartment?.unitNumber ?? '?'} - ${pkg.recipient?.apartment?.tower ?? '?'}";

    return Scaffold(
      appBar: AppBar(title: Text(unitInfo), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          // FOTO
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black12,
              child: pkg.photoKey != null
                  ? FutureBuilder<String>(
                      future: _getImageUrl(pkg.photoKey!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return InteractiveViewer(child: Image.network(snapshot.data!, fit: BoxFit.contain));
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            ),
          ),

          // PANEL DE ACCIONES
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Detalles del Paquete", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _infoRow(Icons.local_shipping, "Empresa:", pkg.courier),
                _infoRow(Icons.access_time, "Llegada:", dateFormatted),
                const Divider(height: 20),

                if (_isDelivering)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      // 🔵 BOTÓN AZUL: ABRE LA FIRMA
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          icon: const Icon(Icons.draw),
                          label: const Text("FIRMAR Y ENTREGAR", style: TextStyle(fontSize: 16)),
                          onPressed: () => _processDeliveryWithSignature(context),
                        ),
                      ),
                      
                      const SizedBox(height: 10),

                      // 🔴 BOTÓN ROJO: NO ABRE FIRMA (Directo)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          icon: const Icon(Icons.warning_amber_rounded),
                          label: const Text("ENTREGA SIN FIRMA", style: TextStyle(fontSize: 16)),
                          onPressed: () => _confirmNoSignature(context),
                        ),
                      ),
                      // --- BOTÓN NUEVO: NOTIFICAR WHATSAPP ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Color WhatsApp
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text("NOTIFICAR AL VECINO (WhatsApp)", style: TextStyle(fontSize: 14)),
onPressed: () async {
                       if (pkg.photoKey == null) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sin foto para compartir.")));
                         return;
                       }

                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⏳ Generando QR y descargando foto..."), duration: Duration(seconds: 2)));

                       // 1. Obtener URL de la foto
                       String url = await _getImageUrl(pkg.photoKey!);
                       if (url.isEmpty) return;

                       // 2. Formatear la fecha bonita
                       String dateStr = "Fecha desconocida";
                       if (pkg.receivedAt != null) {
                          final date = DateTime.parse(pkg.receivedAt.toString()).toLocal();
                          dateStr = DateFormat('dd/MM/yyyy - hh:mm a').format(date);
                       }

                       // 3. Llamar al servicio recargado
                       await WhatsAppService.notificarVecino(
                         photoUrl: url,
                         neighborName: pkg.recipient?.name ?? "Vecino",
                         courier: pkg.courier,
                         tower: pkg.recipient?.apartment?.tower ?? "",
                         unit: pkg.recipient?.apartment?.unitNumber ?? "",
                         packageId: pkg.id, // Enviamos el ID completo para que genere el QR real
                         receivedDate: dateStr, // 🔥 Pasamos la fecha
                       );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                // ----------------------------------------
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}