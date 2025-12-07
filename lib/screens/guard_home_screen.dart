import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importamos nuestros modelos y pantallas
import '../models/ModelProvider.dart';
import 'login_screen.dart';
import 'receive_package_screen.dart';
import 'guard_screen.dart'; // La pantalla de Inventario (Grilla)
import 'qr_scan_screen.dart'; // La pantalla del Escáner

class GuardHomeScreen extends StatelessWidget {
  const GuardHomeScreen({super.key});

  // --- 1. LÓGICA DE CIERRE DE SESIÓN ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Borra datos locales
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al salir: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cerrar Sesión?"),
        content: const Text("Tendrás que ingresar tu usuario y contraseña nuevamente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _signOut(context);
            }, 
            child: const Text("Salir")
          ),
        ],
      ),
    );
  }

  // --- 2. LÓGICA DE ENTREGA (ESCÁNER QR) ---
  Future<void> _handleQRScan(BuildContext context) async {
    // A. Abrir cámara y esperar el código
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanScreen()),
    );

    // Si canceló o no leyó nada, salimos
    if (result == null || !context.mounted) return;

    final String packageId = result;

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🔍 Verificando paquete..."), duration: Duration(seconds: 1)),
    );

    try {
      // B. Buscar el paquete en AWS
      final request = ModelQueries.get(
        Package.classType, 
        PackageModelIdentifier(id: packageId),
        authorizationMode: APIAuthorizationType.apiKey
      );
      final response = await Amplify.API.query(request: request).response;
      final package = response.data;

      // C. Validaciones
      if (package == null) {
        throw Exception("Paquete no encontrado. Código inválido.");
      }

      if (package.status != PackageStatus.IN_WAREHOUSE) {
        throw Exception("Este paquete ya fue entregado anteriormente.");
      }

      // D. Actualizar estado a DELIVERED (Entregado)
      final updatedPackage = package.copyWith(
        status: PackageStatus.DELIVERED,
      );

      final mutation = ModelMutations.update(updatedPackage, authorizationMode: APIAuthorizationType.apiKey);
      final mutationRes = await Amplify.API.mutate(request: mutation).response;

      if (mutationRes.hasErrors) {
        throw Exception(mutationRes.errors.first.message);
      }

      // E. Éxito
      if (context.mounted) {
        _showSuccessDialog(context, package.courier, package.recipient?.apartment?.unitNumber ?? "?");
      }

    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  // --- DIÁLOGOS DE FEEDBACK ---
  void _showSuccessDialog(BuildContext context, String courier, String apto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text("¡Entrega Exitosa!"),
        content: Text("El paquete de $courier para el Apto $apto ha sido marcado como entregado."),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Aceptar"),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 60),
        title: const Text("Error en Entrega"),
        content: Text(error.replaceAll("Exception: ", "")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))
        ],
      ),
    );
  }

  // --- 3. INTERFAZ GRÁFICA (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Portería"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Cerrar Sesión",
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.indigo),
            const SizedBox(height: 10),
            const Text(
              "¿Qué deseas hacer?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // BOTÓN 1: LEER QR (Conectado a la lógica real)
            _MenuButton(
              icon: Icons.qr_code_scanner,
              label: "LEER QR ENTREGA",
              color: Colors.purple,
              onTap: () => _handleQRScan(context),
            ),

            const SizedBox(height: 20),

            // BOTÓN 2: REGISTRAR PAQUETE (Sin const para evitar errores)
            _MenuButton(
              icon: Icons.add_box,
              label: "REGISTRAR PAQUETE",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceivePackageScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            // BOTÓN 3: INVENTARIO (Sin const para evitar errores)
            _MenuButton(
              icon: Icons.grid_view,
              label: "INVENTARIO PENDIENTE",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GuardScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para diseño de botones
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, 
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 35),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}