import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<Package> _myPackages = [];
  bool _isLoading = true;
  String _residentName = "Vecino";

  @override
  void initState() {
    super.initState();
    _loadProfileAndPackages();
  }

  Future<void> _loadProfileAndPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId'); 
    
    setState(() {
      _residentName = prefs.getString('username') ?? "Vecino";
    });

    if (userId != null) {
      _fetchMyPackages(userId);
    } else {
      print("❌ Error: No se encontró User ID en la sesión.");
      setState(() => _isLoading = false);
    }
  }

  // 🔥 FUNCIÓN BLINDADA PARA TRAER PAQUETES
  Future<void> _fetchMyPackages(String userId) async {
    setState(() => _isLoading = true);
    try {
    String graphQLDocument = '''
        query ListMyPackages {
          listPackages(filter: {
            recipientID: {eq: "$userId"}, 
            status: {eq: IN_WAREHOUSE}
          }) {
            items {
              id
              recipientID
              courier
              photoKey
              receivedAt
              status
              recipient {
                id             
                username       
                name
                role           
                isFirstLogin   
                apartment {
                  id           
                  tower
                  unitNumber
                  accessCode   
                }
              }
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final Map<String, dynamic> data = json.decode(response.data!);
        final List items = data['listPackages']['items'];

        List<Package> myPackages = [];
        
        // 🕵️‍♂️ ZONA DE DEPURACIÓN (Mira tu consola)
        print("📦 PAQUETES ENCONTRADOS EN LA NUBE: ${items.length}");

        for (var item in items) {
          try {
            // Imprimimos el dato crudo para ver si tiene 'courier: null'
            print("🔎 Analizando paquete: $item"); 

            if (item == null) continue;

            // Intentamos convertirlo. Si falla aquí, salta al 'catch' de abajo
            final pkg = Package.fromJson(item);
            myPackages.add(pkg);

          } catch (e) {
            // 🛡️ AQUÍ ATRAPAMOS EL ERROR SIN QUE LA APP EXPLOTE
            print("💀 PAQUETE CORRUPTO IGNORADO: $e");
            // No hacemos nada más, simplemente no lo agregamos a la lista
          }
        }

        // Ordenar más recientes primero
        myPackages.sort((a, b) => 
          (b.receivedAt ?? TemporalDateTime.now()).compareTo(a.receivedAt ?? TemporalDateTime.now())
        );

        setState(() {
          _myPackages = myPackages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error general cargando paquetes: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getImageUrl(String key) async {
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(key),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(validateObjectExistence: true, expiresIn: Duration(minutes: 60)),
        ),
      ).result;
      return result.url.toString();
    } catch (e) {
      return "";
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mis Paquetes", style: TextStyle(fontSize: 18)),
            Text("${widget.tower} - Apto ${widget.unit}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadProfileAndPackages()),
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _signOut),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myPackages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      const Text("No tienes paquetes pendientes 🎉", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      // Botón extra por si quieres forzar recarga
                      TextButton.icon(
                        onPressed: () => _loadProfileAndPackages(),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Recargar")
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _myPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = _myPackages[index];
                    
                    // Manejo seguro de fechas
                    String dateStr = "Fecha desconocida";
                    if (pkg.receivedAt != null) {
                       final date = DateTime.parse(pkg.receivedAt.toString()).toLocal();
                       dateStr = DateFormat('dd MMM - hh:mm a').format(date);
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          // A. FOTO
                          if (pkg.photoKey != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: FutureBuilder<String>(
                                  future: _getImageUrl(pkg.photoKey!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        height: 200, 
                                        color: Colors.grey[100], 
                                        child: const Center(child: CircularProgressIndicator())
                                      );
                                    }
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      return Image.network(snapshot.data!, fit: BoxFit.cover);
                                    }
                                    return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
                                  },
                                ),
                              ),
                            ),
                          
                          // B. INFO
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(pkg.courier.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                                      child: const Text("En Portería", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text("Llegó: $dateStr", style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 15),
                                
                                // C. BOTÓN QR
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.qr_code),
                                    label: const Text("VER CÓDIGO DE RETIRO"),
                                    onPressed: () => _showQRDialog(context, pkg),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showQRDialog(BuildContext context, Package pkg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Código de Retiro", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: QrImageView(
                data: pkg.id,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Muestra este código al portero", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar")),
        ],
      ),
    );
  }
}