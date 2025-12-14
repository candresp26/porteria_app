import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  // 🔥 NUEVO: Necesitamos un controlador en la nueva versión
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // Para evitar lecturas múltiples
    returnImage: false,
  );

  @override
  void dispose() {
    controller.dispose(); // Limpiamos el controlador al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear Código QR"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          // Botón opcional para prender linterna
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          // Botón para cambiar cámara (frontal/trasera)
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller, // 👈 Asignamos el controlador
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final String code = barcode.rawValue!;
              
              // Cerramos la pantalla y devolvemos el código
              // Usamos un pequeño delay para asegurar la estabilidad
              controller.stop(); 
              if (mounted) {
                Navigator.pop(context, code);
              }
              break; // Solo leemos el primero
            }
          }
        },
      ),
    );
  }
}