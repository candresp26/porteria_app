import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // Para poder volver al login al salir

class HomeScreen extends StatefulWidget {
  // Recibimos los datos para mostrarlos
  final String tower;
  final String unit;

  const HomeScreen({super.key, required this.tower, required this.unit});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // Función para Cerrar Sesión
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borramos los datos guardados

    if (mounted) {
      // Navegar de vuelta al Login y borrar historial de navegación
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Portería 📦'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              '¡Hola, vecino!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Tu Apartamento:", style: TextStyle(color: Colors.grey[600])),
                    Text(
                      "${widget.tower} - ${widget.unit}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text("No tienes paquetes pendientes (por ahora)."),
          ],
        ),
      ),
    );
  }
}