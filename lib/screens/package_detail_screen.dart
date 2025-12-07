import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:intl/intl.dart';
import '../models/ModelProvider.dart';

class PackageDetailScreen extends StatefulWidget {
  final Package package;
  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
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
    final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(date);
    final unitInfo = "Apto ${pkg.recipient?.apartment?.unitNumber} - Torre ${pkg.recipient?.apartment?.tower}";

    return Scaffold(
      appBar: AppBar(title: Text(unitInfo), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          // 1. FOTO GRANDE (Ocupa espacio flexible)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black12,
              child: pkg.photoKey != null
                  ? FutureBuilder<String>(
                      future: _getImageUrl(pkg.photoKey!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return InteractiveViewer( // Permite hacer zoom a la foto
                            child: Image.network(snapshot.data!, fit: BoxFit.contain),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            ),
          ),

          // 2. PANEL DE INFORMACIÓN Y ACCIONES
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
                const Divider(height: 30),

                // --- BOTONES DE ACCIÓN ---
                
                // OPCIÓN A: ENTREGAR CON QR (Principal)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("ESCANEAR QR DE ENTREGA", style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      // Lógica de abrir cámara para validar
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Abriendo cámara para validar QR...")));
                    },
                  ),
                ),
                
                const SizedBox(height: 10),

                // OPCIÓN B: ENTREGA MANUAL (Secundaria)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    icon: const Icon(Icons.handshake),
                    label: const Text("ENTREGA MANUAL (Sin QR)", style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      // Lógica de confirmar manual (pedir confirmación)
                      _confirmManualDelivery(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para filas de texto
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

  // Diálogo para confirmar entrega manual
  void _confirmManualDelivery(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Confirmar entrega manual?"),
        content: const Text("Usa esto solo si el residente no tiene su celular o el QR falla."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paquete entregado manualmente")));
              // Aquí llamaremos a la API para cambiar estado a DELIVERED
            }, 
            child: const Text("Confirmar")
          ),
        ],
      ),
    );
  }
}