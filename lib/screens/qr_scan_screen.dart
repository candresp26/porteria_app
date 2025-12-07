import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _hasScanned = false; // Para evitar lecturas múltiples muy rápidas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear Código QR"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        // Controlador para detectar códigos
        onDetect: (capture) {
          if (_hasScanned) return; // Si ya leyó uno, ignorar los siguientes frames
          
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            
            setState(() {
              _hasScanned = true; // Bloqueamos lecturas adicionales
            });

            // 🔊 Feedback visual/sonoro podría ir aquí
            
            // Devolvemos el código leído a la pantalla anterior
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}