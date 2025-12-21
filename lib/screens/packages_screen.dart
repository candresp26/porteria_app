import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/ModelProvider.dart';
import 'resident_package_detail_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  bool _isLoading = true;
  
  // Listas separadas para la vista
  List<Package> _pendingPackages = [];
  List<Package> _deliveredPackages = [];
  
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId'); 
      final name = prefs.getString('username') ?? "";

      setState(() => _userName = name);

      if (userId == null || userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ---------------------------------------------------------
      // PASO 1: Obtener mi Apartamento para saber quién es mi familia
      // ---------------------------------------------------------
      List<String> familyIds = [userId]; // Por defecto, solo yo

      try {
        final userReq = ModelQueries.get(
          User.classType, 
          UserModelIdentifier(id: userId),
          authorizationMode: APIAuthorizationType.apiKey // Importante: API Key
        );
        final userRes = await Amplify.API.query(request: userReq).response;
        
        final myUser = userRes.data;

        if (myUser != null && myUser.apartment != null) {
          // Si tengo apartamento, busco a todos los que viven conmigo
          final familyReq = ModelQueries.list(
            User.classType,
            where: User.APARTMENT.eq(myUser.apartment!.id),
            authorizationMode: APIAuthorizationType.apiKey
          );
          final familyRes = await Amplify.API.query(request: familyReq).response;
          
          if (familyRes.data != null) {
            // Actualizamos la lista de IDs con toda la familia
            familyIds = familyRes.data!.items
                .where((u) => u != null)
                .map((u) => u!.id)
                .toList();
          }
        }
      } catch (e) {
        print("⚠️ Error buscando familia, mostrando solo propios: $e");
      }

      // ---------------------------------------------------------
      // PASO 2: Buscar paquetes para CADA miembro de la familia
      // ---------------------------------------------------------
      List<Package> allCollectedPackages = [];

      for (String id in familyIds) {
        // Consultamos paquetes de este usuario
        final pkgReq = ModelQueries.list(
          Package.classType,
          where: Package.RECIPIENT.eq(id),
          authorizationMode: APIAuthorizationType.apiKey
        );
        final pkgRes = await Amplify.API.query(request: pkgReq).response;
        
        if (pkgRes.data != null) {
          allCollectedPackages.addAll(pkgRes.data!.items.whereType<Package>());
        }
      }

      // ---------------------------------------------------------
      // PASO 3: Ordenar y Filtrar (Lógica visual)
      // ---------------------------------------------------------
      
      // Ordenamos: Lo más reciente primero
      allCollectedPackages.sort((a, b) {
         final aTime = a.updatedAt ?? a.createdAt;
         final bTime = b.updatedAt ?? b.createdAt;
         if (aTime == null || bTime == null) return 0;
         return bTime.compareTo(aTime);
      });

      // Fecha límite: Hoy menos 30 días
      final limitDate = DateTime.now().subtract(const Duration(days: 30));

      // Filtros
      final pending = allCollectedPackages.where((p) => p.status == PackageStatus.IN_WAREHOUSE).toList();
      
      final deliveredRecent = allCollectedPackages.where((p) {
        if (p.status == PackageStatus.IN_WAREHOUSE) return false; 
        
        if (p.updatedAt != null) {
          final date = DateTime.parse(p.updatedAt.toString());
          return date.isAfter(limitDate); 
        }
        return true; 
      }).toList();

      if (mounted) {
        setState(() {
          _pendingPackages = pending;
          _deliveredPackages = deliveredRecent;
          _isLoading = false;
        });
      }

    } catch (e) {
      print("🔥 Error fetching packages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text("Mis Paquetes", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // --- FONDO DE BURBUJAS ---
          Positioned(top: -100, right: -100, child: _buildBubble(300, const Color(0xFF0F172A).withOpacity(0.05))),
          Positioned(bottom: 50, left: -50, child: _buildBubble(200, const Color(0xFF2DD4BF).withOpacity(0.1))),

          // --- CONTENIDO ---
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- SECCIÓN 1: EN PORTERÍA ---
                    _buildSectionHeader("En Portería", Icons.notification_important, Colors.orange),
                    const SizedBox(height: 10),
                    
                    if (_pendingPackages.isEmpty)
                      _buildEmptyState("¡Todo al día! No hay paquetes esperando en casa.")
                    else
                      ..._pendingPackages.map((pkg) => _buildPackageCard(context, pkg)),

                    const SizedBox(height: 30),

                    // --- SECCIÓN 2: HISTORIAL (ÚLTIMO MES) ---
                    _buildSectionHeader("Historial (Últimos 30 días)", Icons.history, Colors.grey),
                    const SizedBox(height: 10),

                    if (_deliveredPackages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("No hay entregas recientes.", style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ..._deliveredPackages.map((pkg) => _buildPackageCard(context, pkg)),
                      
                    const SizedBox(height: 40),

                    // --- MENSAJE INFORMATIVO AL FINAL ---
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[500]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Se muestran paquetes de todos los miembros registrados en tu apartamento.",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // Header de Sección
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
      ],
    );
  }

  // Estado Vacío (Verde)
  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // Tarjeta de Paquete
  Widget _buildPackageCard(BuildContext context, Package pkg) {
    final bool isPending = pkg.status == PackageStatus.IN_WAREHOUSE;
    final Color statusColor = isPending ? Colors.orange : Colors.green;
    
    // Formateo seguro de fecha
    String dateStr = "";
    try {
      final targetDate = isPending ? pkg.receivedAt : (pkg.updatedAt ?? pkg.receivedAt);
      if (targetDate != null) {
        final date = DateTime.parse(targetDate.toString()).toLocal();
        dateStr = DateFormat('dd MMM, hh:mm a').format(date);
      }
    } catch (_) {}

    // Intentar obtener el nombre del dueño del paquete si no soy yo
    // (Opcional, pero útil en modo familia. Por ahora mostramos courier)

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isPending ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5) : Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ResidentPackageDetailScreen(package: pkg)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.inventory_2, color: statusColor, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.courier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      // Aquí podríamos mostrar "Para: Nombre" en el futuro
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(isPending ? "RECOGER" : "Entregado", style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Burbuja de Fondo
  Widget _buildBubble(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}