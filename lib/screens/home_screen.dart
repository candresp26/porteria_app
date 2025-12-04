import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart'; 
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String tower;
  final String unit;

  const HomeScreen({super.key, required this.tower, required this.unit});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Package> _myPackages = [];
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final myUserId = prefs.getString('userId');
      final name = prefs.getString('username') ?? "Vecino";

      setState(() => _userName = name);

      if (myUserId == null) return;

      // 1. OBTENER MI APARTAMENTO
      final meReq = ModelQueries.get(
        User.classType, 
        UserModelIdentifier(id: myUserId),
        authorizationMode: APIAuthorizationType.apiKey
      );
      final meRes = await Amplify.API.query(request: meReq).response;
      
      if (meRes.data == null || meRes.data!.apartment == null) {
        print("⚠️ Usuario sin apartamento asignado");
        setState(() => _isLoading = false);
        return;
      }

      final myAptId = meRes.data!.apartment!.id;

      // 2. BUSCAR A MI FAMILIA
      final usersReq = ModelQueries.list(
        User.classType, 
        authorizationMode: APIAuthorizationType.apiKey
      );
      final usersRes = await Amplify.API.query(request: usersReq).response;
      
      // CORRECCIÓN AQUÍ: Usamos whereType<User>() para eliminar nulos antes de procesar
      final allUsers = usersRes.data?.items.whereType<User>() ?? [];
      
      final familyIds = allUsers
          .where((u) => u.apartment?.id == myAptId)
          .map((u) => u.id)
          .toList();

      print("🏠 Familia encontrada: ${familyIds.length} integrantes");

      // 3. BUSCAR PAQUETES DE LA FAMILIA
      final pkgReq = ModelQueries.list(
        Package.classType,
        where: Package.STATUS.eq(PackageStatus.IN_WAREHOUSE),
        authorizationMode: APIAuthorizationType.apiKey,
      );
      final pkgRes = await Amplify.API.query(request: pkgReq).response;
      
      if (pkgRes.data != null) {
        final allPending = pkgRes.data!.items.whereType<Package>();
        
        final householdPackages = allPending.where((p) {
          return familyIds.contains(p.recipient?.id);
        }).toList();

        householdPackages.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        
        setState(() {
          _myPackages = householdPackages;
        });
      }

    } catch (e) {
      print("Error cargando paquetes: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error actualizando: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (mounted) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Portería 📦', style: TextStyle(fontSize: 18)),
            Text('${widget.tower} - ${widget.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _loadData,
            tooltip: "Actualizar lista",
          ), 
          IconButton(
            icon: const Icon(Icons.exit_to_app), 
            onPressed: _logout,
            tooltip: "Cerrar sesión",
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $_userName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.indigo, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _myPackages.isEmpty 
                    ? "Estás al día. No hay paquetes en portería." 
                    : "Tienes ${_myPackages.length} paquete(s) por recoger:",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: _myPackages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                            const SizedBox(height: 10),
                            const Text("Todo limpio por aquí", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _myPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _myPackages[index];
                          final date = pkg.receivedAt.getDateTimeInUtc().toLocal();
                          final dateStr = "${date.day}/${date.month} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                          final destinatarioName = pkg.recipient?.username ?? "Alguien";

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inventory_2, color: Colors.orange),
                              ),
                              title: Text(pkg.courier, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Llegó: $dateStr"),
                                  Text("Para: $destinatarioName", style: TextStyle(fontSize: 12, color: Colors.indigo.shade300)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}