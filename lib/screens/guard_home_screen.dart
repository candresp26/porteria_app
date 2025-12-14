import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ModelProvider.dart';
import 'login_screen.dart';
import 'guard_screen.dart'; // Pantalla de Inventario
import 'receive_package_screen.dart'; // 🔥 IMPORTANTE: Pantalla de Registro
import 'qr_scan_screen.dart'; // Pantalla de Escáner
import 'delivery_history_screen.dart'; // Pantalla de Historial

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  bool _isProcessing = false;

  Future<void> _signOut() async {
    await Amplify.Auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Lógica del QR (Igual que antes)
  Future<void> _handleQRScan() async {
    final String? scannedId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanScreen()),
    );

    if (scannedId == null) return;

    setState(() => _isProcessing = true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔍 Procesando entrega..."), duration: Duration(seconds: 1)),
      );
    }

    try {
      final requestGet = ModelQueries.get(
        Package.classType, 
        PackageModelIdentifier(id: scannedId),
        authorizationMode: APIAuthorizationType.apiKey
      );
      final responseGet = await Amplify.API.query(request: requestGet).response;
      final pkg = responseGet.data;

      if (pkg == null) throw Exception("Paquete no encontrado.");
      if (pkg.status == PackageStatus.DELIVERED) throw Exception("¡Paquete ya entregado!");

      final updatedPkg = pkg.copyWith(status: PackageStatus.DELIVERED);

      final requestUpdate = ModelMutations.update(updatedPkg, authorizationMode: APIAuthorizationType.apiKey);
      final responseUpdate = await Amplify.API.mutate(request: requestUpdate).response;

      if (responseUpdate.hasErrors) throw Exception(responseUpdate.errors.first.message);

      if (mounted) _showSuccessDialog(pkg);

    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Package pkg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.green[50],
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text("¡Entrega Exitosa!")]),
        content: Text("Destinatario: ${pkg.recipient?.name ?? 'Vecino'}\nEmpresa: ${pkg.courier}"),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("Aceptar"))],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(title: const Text("Error"), content: Text(error.replaceAll("Exception: ", "")), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú Portería"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _signOut)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BOTÓN 1: REGISTRAR NUEVO (EL QUE FALTABA) 🔥
            _MenuButton(
              icon: Icons.add_box,
              label: "REGISTRAR NUEVO PAQUETE",
              color: Colors.indigo, // Azul oscuro principal
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceivePackageScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            // BOTÓN 2: INVENTARIO (VER PENDIENTES)
            _MenuButton(
              icon: Icons.inventory,
              label: "VER INVENTARIO PENDIENTE",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuardScreen()),
                );
              },
            ),
            
            const SizedBox(height: 20),

            // BOTÓN 3: LEER QR
            _MenuButton(
              icon: Icons.qr_code_scanner,
              label: "LEER QR DE ENTREGA",
              color: Colors.orange[800]!,
              onTap: _isProcessing ? null : _handleQRScan,
            ),

            const SizedBox(height: 20),

            // BOTÓN 4: HISTORIAL
            _MenuButton(
              icon: Icons.history,
              label: "HISTORIAL ENTREGAS",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeliveryHistoryScreen()),
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