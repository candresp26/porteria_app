import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'login_screen.dart';
import 'coming_soon_screen.dart'; 
import 'manage_guards_screen.dart';
import 'manage_residents_screen.dart';
import 'package_audit_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = "Administrador";

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('name') ?? "Administrador";
    });
  }

  Future<void> _logout() async {
    try {
      await Amplify.Auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); 

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print("Error saliendo: $e");
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para que resalten las burbujas
      extendBodyBehindAppBar: true, // Para que las burbujas suban hasta el techo
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Panel Administrativo", 
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: "Cerrar Sesión",
          )
        ],
      ),
      body: Stack(
        children: [
          // --- BURBUJAS DE FONDO (DISEÑO URBIAN) ---
          Positioned(top: -50, left: -50, child: _buildBubble(200, const Color(0xFF2DD4BF).withOpacity(0.2))),
          Positioned(top: 150, right: -30, child: _buildBubble(120, const Color(0xFF0F172A).withOpacity(0.05))),
          Positioned(bottom: -80, right: -20, child: _buildBubble(250, const Color(0xFF2DD4BF).withOpacity(0.15))),
          Positioned(bottom: 100, left: -40, child: _buildBubble(100, Colors.indigo.withOpacity(0.05))),

          // --- CONTENIDO PRINCIPAL ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Hola, $_adminName",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const Text(
                    "Gestión del Edificio",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // --- GRILLA DE MÓDULOS ---
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        // 1. GESTIÓN DE PORTEROS
                        _buildAdminCard(
                          title: "Porteros",
                          subtitle: "Crear, Bloquear, Pines",
                          icon: Icons.local_police_outlined,
                          color: Colors.blue[800]!,
                          onTap: () {
                            _navigateTo(const ManageGuardsScreen());
                            },
                                                    ),

                        // 2. GESTIÓN DE RESIDENTES
                        _buildAdminCard(
                        title: "Residentes",
                        subtitle: "Cupos, Mudanzas",
                        icon: Icons.people_alt_outlined,
                        color: Colors.purple[700]!,
                        onTap: () {
                            // Conexión realizada ✅
                            _navigateTo(const ManageResidentsScreen());
                        },
                        ),

                    // 3. AUDITORÍA / HISTORIAL
                        _buildAdminCard(
                          title: "Auditoría",
                          subtitle: "Historial de Paquetes",
                          icon: Icons.history_edu_outlined,
                          color: Colors.orange[800]!,
                          onTap: () {
                             // ✅ AHORA SÍ: Navegar a la pantalla real
                             _navigateTo(const PackageAuditScreen());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS VISUALES ---

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}