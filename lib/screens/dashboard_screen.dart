import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para cerrar sesión si quieres
import 'coming_soon_screen.dart'; 

// IMPORTANTE: Aquí conectamos con tu pantalla que YA funciona.
// Verifica que la ruta del archivo sea correcta según tu proyecto.
import 'resident_home_screen.dart'; 
import 'login_screen.dart'; // Por si implementamos el Logout

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Función para cerrar sesión (Opcional, pero útil en el menú)
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borra datos locales
    // Aquí podrías agregar Amplify.Auth.signOut() si lo necesitas
    if (context.mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => LoginScreen())
      );
    }
  }

  void _navigateTo(BuildContext context, String title, bool isReady) {
    if (isReady) {
      // ✅ CAMINO FELIZ: Navega a tu pantalla existente de Paquetes
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => const ResidentHomeScreen()) 
      );
    } else {
      // 🚧 CAMINO EN CONSTRUCCIÓN
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => ComingSoonScreen(moduleName: title))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Configuración de las burbujas
    final List<Map<String, dynamic>> menuOptions = [
      {
        'title': 'Mis Paquetes',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.blueAccent,
        'isReady': true, // 👈 ESTE ES EL QUE LLEVA A RESIDENT_HOME_SCREEN
      },
      {
        'title': 'Zonas Comunes',
        'icon': Icons.deck_outlined,
        'color': Colors.teal,
        'isReady': false,
      },
      {
        'title': 'Asamblea',
        'icon': Icons.how_to_vote_outlined,
        'color': Colors.orange,
        'isReady': false,
      },
      {
        'title': 'Invitados',
        'icon': Icons.person_add_alt_1_outlined,
        'color': Colors.purpleAccent,
        'isReady': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("URBIAN"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        automaticallyImplyLeading: false, // Quita botón de atrás
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Cerrar Sesión",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Hola, Vecino 👋', 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
            ),
            const Text(
              'Selecciona una opción para empezar', 
              style: TextStyle(color: Colors.grey, fontSize: 14)
            ),
            const SizedBox(height: 20),
            
            // GRILLA DE BURBUJAS
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columnas
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.0, // Cuadrados perfectos
                ),
                itemCount: menuOptions.length,
                itemBuilder: (context, index) {
                  final option = menuOptions[index];
                  return _buildBubbleCard(
                    context, 
                    option['title'], 
                    option['icon'], 
                    option['color'], 
                    option['isReady']
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleCard(BuildContext context, String title, IconData icon, Color color, bool isReady) {
    return GestureDetector(
      onTap: () => _navigateTo(context, title, isReady),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            if (!isReady)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  'Pronto', 
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)
                ),
              )
          ],
        ),
      ),
    );
  }
}