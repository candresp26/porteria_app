import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';

// Helper de fecha BLINDADO 🛡️
String _formatDate(dynamic dateData) {
  if (dateData == null) return "Reciente"; 
  
  try {
    DateTime date;
    if (dateData is TemporalDateTime) {
      date = DateTime.parse(dateData.toString()).toLocal();
    } else if (dateData is String) {
      date = DateTime.parse(dateData).toLocal();
    } else {
      return "--/--";
    }
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    return "Error fecha";
  }
}

class PackageAuditScreen extends StatefulWidget {
  const PackageAuditScreen({super.key});

  @override
  State<PackageAuditScreen> createState() => _PackageAuditScreenState();
}

class _PackageAuditScreenState extends State<PackageAuditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<Package> _pendingPackages = [];
  List<Package> _historyPackages = [];
  List<AuditLog> _systemLogs = []; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchPackages(),
        _fetchSystemLogs(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPackages() async {
    try {
      final request = ModelQueries.list(Package.classType);
      final response = await Amplify.API.query(request: request).response;
      if (response.data != null) {
        final allPackages = response.data!.items.whereType<Package>().toList();
        final pending = <Package>[];
        final history = <Package>[];
        
        for (var pkg in allPackages) {
          (pkg.status == PackageStatus.IN_WAREHOUSE) ? pending.add(pkg) : history.add(pkg);
        }

        // --- ORDENAMIENTO ROBUSTO (LO MÁS NUEVO ARRIBA) ---
        pending.sort((a, b) {
           final da = a.createdAt;
           final db = b.createdAt;
           if (da == null) return 1; 
           if (db == null) return -1;
           return db.compareTo(da); // Descendente
        });

        history.sort((a, b) {
           final da = a.updatedAt;
           final db = b.updatedAt;
           if (da == null) return 1;
           if (db == null) return -1;
           return db.compareTo(da);
        });
        
        if (mounted) {
          setState(() {
            _pendingPackages = pending;
            _historyPackages = history;
          });
        }
      }
    } catch (e) {
      print("Error packages: $e");
    }
  }

  Future<void> _fetchSystemLogs() async {
    try {
      final request = ModelQueries.list(AuditLog.classType);
      final response = await Amplify.API.query(request: request).response;
      if (response.data != null) {
        final logs = response.data!.items.whereType<AuditLog>().toList();
        
        // --- ORDENAMIENTO ROBUSTO LOGS ---
        logs.sort((a, b) {
           final da = a.createdAt;
           final db = b.createdAt;
           if (da == null) return 1; 
           if (db == null) return -1;
           return db.compareTo(da); 
        });

        if (mounted) setState(() => _systemLogs = logs);
      }
    } catch (e) {
      print("Error logs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Centro de Auditoría", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          isScrollable: true, 
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: "En Portería"),
            Tab(icon: Icon(Icons.history), text: "Entregados"),
            Tab(icon: Icon(Icons.security), text: "Logs Sistema"), 
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPackageList(_pendingPackages, isHistory: false),
                _buildPackageList(_historyPackages, isHistory: true),
                _buildSystemLogList(), 
              ],
            ),
    );
  }

  // --- WIDGET LISTA DE PAQUETES ---
  Widget _buildPackageList(List<Package> packages, {required bool isHistory}) { 
     if (packages.isEmpty) return const Center(child: Text("Sin datos"));
     
     final Map<PackageStatus, String> statusTranslations = {
       PackageStatus.IN_WAREHOUSE: "En Portería",
       PackageStatus.DELIVERED: "Entregado",
     };

     return ListView.builder(
       padding: const EdgeInsets.all(15),
       itemCount: packages.length,
       itemBuilder: (ctx, i) {
         final pkg = packages[i];
         
         String statusText = statusTranslations[pkg.status] ?? pkg.status.name;
         Color statusColor = pkg.status == PackageStatus.IN_WAREHOUSE ? Colors.orange : Colors.green;

         // Validamos si el dato viene nulo desde la base de datos
         String aptText = pkg.apartmentUnit ?? "---"; 

         return Card(
           margin: const EdgeInsets.only(bottom: 10),
           elevation: 2,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           child: ListTile(
             contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
             leading: Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
               child: Icon(Icons.inventory_2, color: statusColor),
             ),
             title: Text(
               "Apto: $aptText", 
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
             ),
             subtitle: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const SizedBox(height: 5),
                 Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
               ],
             ),
             trailing: Text(
               _formatDate(pkg.updatedAt),
               style: const TextStyle(fontSize: 10, color: Colors.grey),
             ),
           )
         );
       },
     );
  }

  // --- WIDGET LOGS DEL SISTEMA (CORREGIDO) ---
  Widget _buildSystemLogList() {
    if (_systemLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No hay registros aún", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _systemLogs.length,
      itemBuilder: (context, index) {
        // 🔥 AQUÍ SE DEFINE 'log'. Todo uso de 'log' debe estar dentro de las llaves de este builder
        final log = _systemLogs[index]; 
        
        IconData icon = Icons.info_outline;
        Color color = Colors.blue;
        
        if (log.action.contains("BLOQUEAR")) { icon = Icons.block; color = Colors.red; }
        else if (log.action.contains("ACTIVAR")) { icon = Icons.check_circle; color = Colors.green; }
        else if (log.action.contains("CREAR")) { icon = Icons.add_circle; color = Colors.indigo; }

        String actionTitle = log.action.replaceAll("_", " ");
        String targetText = log.targetName ?? "Usuario";
        String adminText = log.actorName ?? "Desconocido";

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 15),
                          children: [
                            TextSpan(text: "$actionTitle a: ", style: const TextStyle(fontWeight: FontWeight.w500)),
                            TextSpan(text: targetText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Por Admin: $adminText",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                       Text(
                        "Detalle: ${log.details ?? ''}",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // ✅ AQUÍ ESTÁ EL ARREGLO DE LLAVES
                Text(
                  _formatDate(log.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}