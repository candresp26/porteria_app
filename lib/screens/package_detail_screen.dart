import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ModelProvider.dart';
import '../widgets/signature_pad.dart';
import '../widgets/guard_pin_dialog.dart'; // Asegúrate de tener este archivo creado

class PackageDetailScreen extends StatefulWidget {
  final Package? package; 
  final String? packageId; 

  const PackageDetailScreen({
    super.key, 
    this.package, 
    this.packageId
  });

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _isDelivering = false;
  bool _isLoading = true; 
  bool _isSharing = false;
  String? _cachedImageUrl;
  Package? _currentPackage; 

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // CASO A: Ya nos pasaron el paquete completo
    if (widget.package != null) {
      setState(() {
        _currentPackage = widget.package;
        _isLoading = false;
      });
      return;
    }

    // CASO B: Venimos del QR (solo tenemos ID)
    if (widget.packageId != null) {
      try {
        final request = ModelQueries.get(
          Package.classType, 
          PackageModelIdentifier(id: widget.packageId!)
        );
        
        final response = await Amplify.API.query(
          request: GraphQLRequest<Package?>(
            document: request.document,
            variables: request.variables,
            modelType: request.modelType,
            decodePath: request.decodePath,
            authorizationMode: APIAuthorizationType.apiKey 
          )
        ).response;
        
        if (response.data != null) {
          setState(() {
            _currentPackage = response.data;
            _isLoading = false;
          });
        } else {
          _handleError("Paquete no encontrado en la base de datos.");
        }
      } catch (e) {
        _handleError("Error buscando paquete: $e");
      }
    } else {
      _handleError("Error: No se proporcionó información del paquete");
    }
  }

  void _handleError(String msg) {
    if(!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    Navigator.pop(context); 
  }

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

  // 👇 LÓGICA DE COMPARTIR QR + TEXTO
  Future<void> _sharePackageInfo() async {
    if (_currentPackage == null) return;
    setState(() => _isSharing = true);
    try {
      final pkg = _currentPackage!;

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

        final picData = await painter.toImageData(800.0); 
        
        if (picData != null) {
          final tempDir = await getTemporaryDirectory();
          final path = '${tempDir.path}/qr_entrega.png';
          final file = await File(path).create();
          await file.writeAsBytes(picData.buffer.asUint8List());

          final String message = """
👋 Hola, ¿me ayudas a recoger mi paquete?

📦 Empresa: ${pkg.courier}
🏢 Apto: ${pkg.recipient?.unit ?? '?'} - ${pkg.recipient?.tower ?? '?'}

¡Muestra el QR adjunto en portería! Gracias.
""";

          await Share.shareXFiles(
            [XFile(path, mimeType: 'image/png')], 
            text: message,
            subject: 'Recoger Paquete',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // 👇 FLUJO DE ENTREGA CON FIRMA + PIN
  Future<void> _processDeliveryWithSignature(BuildContext context) async {
    // 1. Pedir PIN al Portero
    final String? guardName = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GuardPinDialog(action: "Entregar"),
    );

    if (guardName == null) return;

    // 2. Pedir Firma al Residente
    final Uint8List? signatureBytes = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignaturePad(),
    );

    if (signatureBytes == null) return;

    // 3. Ejecutar
    _executeDelivery(DeliveryMethod.MANUAL_WITH_SIGNATURE, signatureBytes, guardName);
  }

  // 👇 FLUJO DE ENTREGA SIN FIRMA + PIN
  Future<void> _confirmNoSignature(BuildContext context) async {
    // Confirmación visual
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Entregar SIN firma?", style: TextStyle(color: Colors.red)),
        content: const Text("⚠️ Esta acción quedará marcada en rojo en el historial."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Continuar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Pedir PIN al Portero (Obligatorio para saber quién entregó)
    final String? guardName = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GuardPinDialog(action: "Autorizar Entrega"),
    );

    if (guardName == null) return;

    // 2. Ejecutar sin firma
    _executeDelivery(DeliveryMethod.MANUAL_NO_SIGNATURE, null, guardName);
  }

  // 👇 FUNCIÓN CENTRALIZADA (CORREGIDA)
  Future<void> _executeDelivery(DeliveryMethod method, Uint8List? signatureData, String? guardName) async {
    if (_currentPackage == null) return; 
    setState(() => _isDelivering = true);
    
    try {
      String? sigKey; // Declaramos la variable aquí para solucionar el error
      
      // 1. Subir Firma a S3 (si existe)
      if (signatureData != null) {
        sigKey = "signatures/${_currentPackage!.id}.png"; 
        
        await Amplify.Storage.uploadData(
          data: StorageDataPayload.bytes(signatureData),
          path: StoragePath.fromString(sigKey),
           options: const StorageUploadDataOptions(
             pluginOptions: S3UploadDataPluginOptions(getProperties: true)
          )
        ).result;
      }

      // 2. Actualizar Base de Datos
      final updatedPkg = _currentPackage!.copyWith(
        status: PackageStatus.DELIVERED,
        deliveryMethod: method,
        signatureKey: sigKey, // Ahora sigKey sí existe
        deliveredBy: guardName // Guardamos quién lo entregó
      );

      final request = ModelMutations.update(updatedPkg, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        throw Exception(response.errors.first.message);
      }

      // 3. Éxito
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Entregado por $guardName"), 
            backgroundColor: Colors.green
          )
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentPackage == null) {
      return const Scaffold(body: Center(child: Text("No se pudo cargar el paquete")));
    }

    final pkg = _currentPackage!; 
    final bool isDelivered = pkg.status == PackageStatus.DELIVERED;

    String dateFormatted = "Fecha desc.";
    try {
       if (pkg.receivedAt != null) {
          final date = DateTime.parse(pkg.receivedAt.toString()).toLocal();
          dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(date);
       }
    } catch(e) { print(e); }

    final unitInfo = "Apto ${pkg.recipient?.unit ?? '?'} - ${pkg.recipient?.tower ?? '?'}";

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Detalles del Paquete", style: Theme.of(context).textTheme.titleLarge),
                    if (isDelivered) 
                      const Chip(label: Text("YA ENTREGADO"), backgroundColor: Colors.orange)
                  ],
                ),
                const SizedBox(height: 10),
                _infoRow(Icons.local_shipping, "Empresa:", pkg.courier),
                _infoRow(Icons.access_time, "Llegada:", dateFormatted),
                if (pkg.receivedBy != null)
                   _infoRow(Icons.person_pin, "Recibido por:", pkg.receivedBy!),
                
                const Divider(height: 20),

                if (_isDelivering)
                  const Center(child: CircularProgressIndicator())
                else if (isDelivered)
                   SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("VOLVER"),
                    ),
                  )
                else
                  Column(
                    children: [
                      // BOTÓN AZUL: FIRMAR
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

                      // BOTÓN ROJO: SIN FIRMA
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
                      
                      const SizedBox(height: 10),

                      // BOTÓN WHATSAPP
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          icon: _isSharing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.share),
                          label: Text(_isSharing ? "GENERANDO..." : "NOTIFICAR AL VECINO", style: const TextStyle(fontSize: 14)),
                          onPressed: _isSharing ? null : _sharePackageInfo,
                        ),
                      ),
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