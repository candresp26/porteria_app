import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import '../models/ModelProvider.dart';
import 'package_detail_screen.dart';

class GuardScreen extends StatefulWidget {
  const GuardScreen({super.key});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  // DOS LISTAS: Una maestra (todos) y una para mostrar (filtrados)
  List<Package> _allPackages = []; 
  List<Package> _foundPackages = []; 
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  // 1. CARGAR PAQUETES (Query Completo)
  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    try {
      const graphQLDocument = '''
        query ListPackagesPending {
          listPackages(filter: {status: {eq: IN_WAREHOUSE}}) {
            items {
              id
              courier
              photoKey
              receivedAt
              status
              recipient {
                id
                name
                apartment {
                  id
                  tower
                  unitNumber
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

        List<Package> loadedPackages = items.map((item) {
          return Package.fromJson(item);
        }).toList();

        loadedPackages.sort((a, b) => 
          (b.receivedAt ?? TemporalDateTime.now()).compareTo(a.receivedAt ?? TemporalDateTime.now())
        );

        setState(() {
          _allPackages = loadedPackages;
          _foundPackages = loadedPackages; // Al inicio mostramos todo
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando paquetes: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. LÓGICA DEL BUSCADOR 🔍
  void _runFilter(String enteredKeyword) {
    List<Package> results = [];
    if (enteredKeyword.isEmpty) {
      // Si borran el texto, mostramos todo de nuevo
      results = _allPackages;
    } else {
      // Filtramos: ¿El texto escrito está en el N° Apto O en la Torre?
      results = _allPackages.where((pkg) {
        final unit = pkg.recipient?.apartment?.unitNumber.toLowerCase() ?? "";
        final tower = pkg.recipient?.apartment?.tower.toLowerCase() ?? "";
        final search = enteredKeyword.toLowerCase();
        
        return unit.contains(search) || tower.contains(search);
      }).toList();
    }

    setState(() {
      _foundPackages = results;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario Pendiente"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPackages),
        ],
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Buscar apartamento (ej: 501, Torre A)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _runFilter('');
                      },
                    ) 
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // --- GRILLA DE RESULTADOS ---
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _foundPackages.isEmpty
                  ? const Center(
                      child: Text(
                        "No se encontraron paquetes.", 
                        style: TextStyle(fontSize: 16, color: Colors.grey)
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPackages,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.60, // Mantenemos la proporción corregida
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _foundPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _foundPackages[index];
                          final unitNum = pkg.recipient?.apartment?.unitNumber ?? '?';
                          final tower = pkg.recipient?.apartment?.tower ?? '?';

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PackageDetailScreen(package: pkg),
                                ),
                              ).then((_) {
                                _fetchPackages();
                                _searchController.clear(); // Limpiamos búsqueda al volver
                              });
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // FOTO
                                  Expanded(
                                    flex: 4,
                                    child: pkg.photoKey != null
                                        ? FutureBuilder<String>(
                                            future: _getImageUrl(pkg.photoKey!),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                                return Image.network(snapshot.data!, fit: BoxFit.cover);
                                              }
                                              return Container(color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.grey));
                                            },
                                          )
                                        : Container(color: Colors.grey[300], child: const Icon(Icons.inventory_2, color: Colors.grey)),
                                  ),
                                  // TEXTO
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            unitNum,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          Text(
                                            "Torre $tower",
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}