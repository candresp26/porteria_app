import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart'; // Aunque no se use directo aquí, a veces es necesario por tipos
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'guard_screen.dart'; // Inventario
import 'receive_package_screen.dart'; // Registro
import 'qr_scan_screen.dart'; // Escáner
import 'delivery_history_screen.dart'; // Historial

// 👇 IMPORTANTE: Importamos la pantalla de Detalle/Firma
import 'package_detail_screen.dart'; 

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  
  // Eliminamos _isProcessing porque la navegación es inmediata

// En guard_home_screen.dart

Future<void> _signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Salvar biometría
      bool biometricEnabled = prefs.getBool('useBiometrics') ?? false;
      String? savedEmail = prefs.getString('email');

      // 2. Cerrar sesión en AWS y Borrar Storage Local
      await Amplify.Auth.signOut();
      await prefs.clear();

      // 3. Restaurar biometría
      if (biometricEnabled) {
        await prefs.setBool('useBiometrics', true);
        if (savedEmail != null) await prefs.setString('email', savedEmail);
      }

    } catch (e) {
      print("Error al salir: $e");
    }
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
}

  // 🔥 Lógica del QR ACTUALIZADA
  Future<void> _handleQRScan() async {
    // 1. Abrimos la cámara para escanear
    final String? scannedId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanScreen()),
    );

    // Si canceló o no leyó nada, no hacemos nada
    if (scannedId == null) return;

    if (!mounted) return;

    // 2. EN LUGAR DE ENTREGAR DE UNA VEZ, NAVEGAMOS AL DETALLE
    // Le pasamos el ID escaneado a la pantalla híbrida que creamos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailScreen(packageId: scannedId),
      ),
    ).then((value) {
      // Opcional: Si quieres hacer algo cuando regrese (ej. actualizar un contador), hazlo aquí
      print("Regresó de la pantalla de firma");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú Portería"),
        backgroundColor: const Color(0xFF0F172A), // Azul oscuro corporativo
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _signOut)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BOTÓN 1: REGISTRAR NUEVO
            _MenuButton(
              icon: Icons.add_box,
              label: "REGISTRAR NUEVO PAQUETE",
              color: const Color(0xFF0F172A), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceivePackageScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            // BOTÓN 2: INVENTARIO
            _MenuButton(
              icon: Icons.inventory,
              label: "VER INVENTARIO PENDIENTE",
              color: Colors.blue[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuardScreen()),
                );
              },
            ),
            
            const SizedBox(height: 20),

            // BOTÓN 3: LEER QR (Ahora va a la firma)
            _MenuButton(
              icon: Icons.qr_code_scanner,
              label: "LEER QR DE ENTREGA",
              color: Colors.orange[800]!,
              onTap: _handleQRScan, // Llamamos a la nueva función simple
            ),

            const SizedBox(height: 20),

            // BOTÓN 4: HISTORIAL
            _MenuButton(
              icon: Icons.history,
              label: "HISTORIAL ENTREGAS",
              color: Colors.green[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeliveryHistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: onTap,
      ),
    );
  }
}