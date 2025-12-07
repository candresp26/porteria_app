import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para obtener el ID del usuario actual
import 'login_screen.dart';
import '../models/ModelProvider.dart';
import 'resident_package_detail_screen.dart'; // 👈 Importamos la nueva pantalla

class HomeScreen extends StatefulWidget {
  final String tower;
  final String unit;

  const HomeScreen({super.key, required this.tower, required this.unit});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Package> _myPackages = [];
  bool _isLoading = true;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? "Vecino";
    });
    _fetchMyPackages();
  }

// 1. TRAER SOLO MIS PAQUETES (Corregido para leer ID de SharedPreferences)
  Future<void> _fetchMyPackages() async {
    setState(() => _isLoading = true);
    try {
      // ❌ ANTES: Esto fallaba porque no usamos Cognito para el login
      // final user = await Amplify.Auth.getCurrentUser(); 
      
      // ✅ AHORA: Leemos el ID que guardamos en el Login manualmente
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId'); 

      if (currentUserId == null) {
        print("⚠️ Error: No se encontró un ID de usuario guardado localmente.");
        setState(() => _isLoading = false);
        return;
      }

      // Consultamos TODOS los paquetes
      final request = ModelQueries.list(
        Package.classType, 
        authorizationMode: APIAuthorizationType.apiKey
      );
      
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        // Filtramos usando el ID que recuperamos del celular
        final pkgs = response.data!.items
            .whereType<Package>()
            .where((p) => p.recipient?.id == currentUserId) // 👈 Aquí usamos el ID local
            .toList();

        // Ordenamos: Lo más reciente primero
        pkgs.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        
        setState(() {
          _myPackages = pkgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando paquetes: $e");
      setState(() => _isLoading = false);
    }
  }
  // Helper imagen (Para la miniatura en la lista)
  Future<String> _getImageUrl(String key) async {
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(key),
        options: const StorageGetUrlOptions(pluginOptions: S3GetUrlPluginOptions(validateObjectExistence: true, expiresIn: Duration(minutes: 60))),
      ).result;
      return result.url.toString();
    } catch (e) { return ""; }
  }
  
  // Cerrar Sesión
  Future<void> _signOut() async {
    await Amplify.Auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hola, $_userName", style: const TextStyle(fontSize: 16)),
            Text("Apto ${widget.unit} - Torre ${widget.tower}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _signOut)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _myPackages.isEmpty 
            ? const Center(child: Text("No tienes paquetes pendientes 🎉"))
            : RefreshIndicator(
                onRefresh: _fetchMyPackages,
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _myPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = _myPackages[index];
                    final isPending = pkg.status == PackageStatus.IN_WAREHOUSE;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      // Si ya se entregó, se pone un poco gris
                      color: isPending ? Colors.white : Colors.grey[100],
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                          child: pkg.photoKey != null 
                            ? FutureBuilder<String>(
                                future: _getImageUrl(pkg.photoKey!),
                                builder: (ctx, snap) => snap.hasData ? Image.network(snap.data!, fit: BoxFit.cover) : const Icon(Icons.image)
                              )
                            : const Icon(Icons.inventory_2),
                        ),
                        title: Text(pkg.courier, style: TextStyle(fontWeight: FontWeight.bold, color: isPending ? Colors.black : Colors.grey)),
                        subtitle: Text(isPending ? "🔵 En Portería - Toca para ver QR" : "✅ Entregado", 
                          style: TextStyle(color: isPending ? Colors.blue : Colors.green)
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // AL TOCAR, VAMOS AL DETALLE CON QR
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ResidentPackageDetailScreen(package: pkg))
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}