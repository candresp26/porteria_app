import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart'; 

import 'login_screen.dart';
import 'coming_soon_screen.dart';
import 'packages_screen.dart'; 

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  String _userName = "Vecino";
  String _displayUnit = "";
  
  // VARIABLES DE BÚSQUEDA
  String? _savedTower;
  String? _savedUnit;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? "Vecino";
      _savedTower = prefs.getString('tower');
      _savedUnit = prefs.getString('unit');
      _displayUnit = "${_savedTower ?? ''} - ${_savedUnit ?? ''}";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    bool biometricEnabled = prefs.getBool('useBiometrics') ?? false;
    String? savedEmail = prefs.getString('email');

    await prefs.clear(); 

    if (biometricEnabled) {
      await prefs.setBool('useBiometrics', true);
      if (savedEmail != null) {
        await prefs.setString('email', savedEmail); 
      }
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- LÓGICA DEL MÓDULO MI APTO ---
  
  void _showApartmentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return FutureBuilder<ApartmentData>(
              future: _fetchApartmentData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final data = snapshot.data!;
                final neighbors = data.neighbors;
                final maxCapacity = data.capacity;
                final occupied = neighbors.length;
                final available = maxCapacity - occupied;

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Mi Apartamento", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: available > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              available > 0 ? "$available Cupos disp." : "Apto Lleno",
                              style: TextStyle(fontWeight: FontWeight.bold, color: available > 0 ? Colors.green : Colors.red),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Ocupación: $occupied / $maxCapacity personas", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const Divider(height: 30),

                      Expanded(
                        child: ListView(
                          controller: controller,
                          children: [
                            if (neighbors.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("No se encontraron residentes registrados en esta unidad.", textAlign: TextAlign.center),
                              ),

                            ...neighbors.map((user) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  (user?.name != null && user!.name!.isNotEmpty) 
                                      ? user!.name!.substring(0, 1).toUpperCase() 
                                      : "U", 
                                  style: const TextStyle(color: Colors.indigo)
                                ),
                              ),
                              title: Text(user?.name ?? "Usuario", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user?.email ?? ""),
                              trailing: (user?.name == _userName || user?.username == _userName) 
                                ? const Chip(label: Text("Yo", style: TextStyle(fontSize: 10))) 
                                : null,
                            )),

                            if (available > 0)
                              ...List.generate(available, (index) => ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person_outline, color: Colors.white),
                                ),
                                title: Text("Espacio Disponible ${index + 1}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                trailing: const Icon(Icons.add_circle_outline, color: Colors.grey),
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- BÚSQUEDA CORREGIDA Y LIMPIA ---
  Future<ApartmentData> _fetchApartmentData() async {
    try {
      // 1. Validar que tengamos datos de ubicación
      if (_savedTower == null || _savedUnit == null) {
        print("❌ Error: No hay Torre/Unidad guardada en preferencias.");
        return ApartmentData([], 3);
      }

      print("🔍 Buscando vecinos en Torre: $_savedTower, Unidad: $_savedUnit");

      // 2. Consulta Directa (Ahora usa autenticación de Cognito por defecto)
      final neighborsReq = ModelQueries.list(
        User.classType, 
        where: User.TOWER.eq(_savedTower).and(User.UNIT.eq(_savedUnit))
      );
      
      // ALERTA: Aquí quitamos el bloque de API Key. 
      // Amplify usará automáticamente el token del usuario logueado.
      final neighborsRes = await Amplify.API.query(request: neighborsReq).response;

      final neighborsList = neighborsRes.data?.items.whereType<User>().toList() ?? [];

      print("✅ Vecinos encontrados: ${neighborsList.length}");

      // 3. Obtener Capacidad Real
      int realCapacity = 3; 

      if (neighborsList.isNotEmpty) {
        final firstUser = neighborsList.first;
        if (firstUser.apartment != null) {
           try {
             final aptReq = ModelQueries.get(
                Apartment.classType, 
                ApartmentModelIdentifier(id: firstUser.apartment!.id)
             );
             final aptRes = await Amplify.API.query(request: aptReq).response;
             if (aptRes.data != null) {
               realCapacity = aptRes.data!.maxResidents ?? 3;
             }
           } catch (e) {
             print("⚠️ No se pudo leer la capacidad del apto: $e");
           }
        }
      }

      return ApartmentData(neighborsList, realCapacity);

    } catch (e) {
      print("🔥 Error buscando datos del apto: $e");
      return ApartmentData([], 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: "Cerrar Sesión",
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, left: -50, child: _buildBubble(200, const Color(0xFF2DD4BF).withOpacity(0.2))),
          Positioned(top: 150, right: -30, child: _buildBubble(120, const Color(0xFF0F172A).withOpacity(0.05))),
          Positioned(bottom: -80, right: -20, child: _buildBubble(250, const Color(0xFF2DD4BF).withOpacity(0.15))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hola,", style: TextStyle(fontSize: 28, color: Colors.grey)),
                  Text(_userName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  
                  if (_displayUnit.length > 3) 
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
                      child: Text("Apto $_displayUnit", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  
                  const SizedBox(height: 40),
                  const Text("¿Qué deseas hacer hoy?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildMenuCard(
                          icon: Icons.home_work_outlined,
                          title: "Mi Apto",
                          color: Colors.indigo,
                          onTap: () => _showApartmentDetails(context),
                        ),
                        _buildMenuCard(
                          icon: Icons.inventory_2_outlined,
                          title: "Mis Paquetes",
                          color: const Color(0xFF2DD4BF), 
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const PackagesScreen()));
                          },
                        ),
                        _buildMenuCard(
                          icon: Icons.people_outline,
                          title: "Invitados",
                          color: Colors.orangeAccent,
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const ComingSoonScreen(moduleName: "Invitados")));
                          },
                        ),
                        _buildMenuCard(
                          icon: Icons.pool,
                          title: "Zonas Comunes",
                          color: Colors.blueAccent,
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const ComingSoonScreen(moduleName: "Zonas Comunes")));
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

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}

class ApartmentData {
  final List<User?> neighbors;
  final int capacity;
  ApartmentData(this.neighbors, this.capacity);
}