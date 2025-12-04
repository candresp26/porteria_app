import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';

class DeliverPackageScreen extends StatefulWidget {
  const DeliverPackageScreen({super.key});

  @override
  State<DeliverPackageScreen> createState() => _DeliverPackageScreenState();
}

class _DeliverPackageScreenState extends State<DeliverPackageScreen> {
  // Datos para Dropdowns
  List<Apartment> _allApartments = [];
  List<String> _towers = [];
  List<Apartment> _unitsInTower = [];
  
  String? _selectedTower;
  Apartment? _selectedApartment;
  
  List<Package> _pendingPackages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  // 1. Carga inicial de Apartamentos
  Future<void> _loadApartments() async {
    try {
      final request = ModelQueries.list(Apartment.classType, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.query(request: request).response;
      
      if (response.data != null) {
        setState(() {
          _allApartments = response.data!.items.whereType<Apartment>().toList();
          _towers = _allApartments.map((a) => a.tower).toSet().toList();
          _towers.sort();
        });
      }
    } catch (e) {
      print("Error cargando aptos: $e");
    }
  }

  void _onTowerChanged(String? newTower) {
    if (newTower == null) return;
    setState(() {
      _selectedTower = newTower;
      _selectedApartment = null;
      _pendingPackages = [];
      _unitsInTower = _allApartments.where((a) => a.tower == newTower).toList();
      _unitsInTower.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    });
  }

  // 2. BUSCAR PAQUETES (Estrategia corregida)
  Future<void> _loadPackagesForApt(Apartment apto) async {
    setState(() {
      _selectedApartment = apto;
      _isLoading = true;
      _pendingPackages = [];
    });

    try {
      // PASO A: Encontrar los IDs de los residentes de este apartamento
      // (Esto evita el problema de profundidad en la consulta de paquetes)
      final userReq = ModelQueries.list(User.classType, authorizationMode: APIAuthorizationType.apiKey);
      final userRes = await Amplify.API.query(request: userReq).response;
      
      final residentsIds = userRes.data?.items
          .where((u) => u?.apartment?.id == apto.id)
          .map((u) => u!.id)
          .toList() ?? [];

      if (residentsIds.isEmpty) {
        print("⚠️ No se encontraron residentes en ${apto.unitNumber}");
        setState(() => _isLoading = false);
        return;
      }

      // PASO B: Traer paquetes y filtrar por esos IDs
      final pkgReq = ModelQueries.list(
        Package.classType,
        where: Package.STATUS.eq(PackageStatus.IN_WAREHOUSE),
        authorizationMode: APIAuthorizationType.apiKey,
      );
      final pkgRes = await Amplify.API.query(request: pkgReq).response;

      if (pkgRes.data != null) {
        final allPending = pkgRes.data!.items.whereType<Package>();
        
        // Filtramos: ¿El destinatario del paquete está en la lista de residentes?
        final packagesForThisApt = allPending.where((p) {
          return residentsIds.contains(p.recipient?.id);
        }).toList();

        // Ordenar por fecha
        packagesForThisApt.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

        setState(() {
          _pendingPackages = packagesForThisApt;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _markAsDelivered(Package pkg) async {
    setState(() => _isLoading = true);
    try {
      print("Entregando paquete ID: ${pkg.id}");
      
      // FRANCOTIRADOR: Mutation Manual
      // Solo actualizamos estado y fecha.
      // Solo pedimos de vuelta el ID y el Estado. NO pedimos el Recipient.
      
      const graphQLDocument = '''
        mutation UpdatePackage(\$id: ID!, \$status: PackageStatus!, \$deliveredAt: AWSDateTime!) {
          updatePackage(input: {
            id: \$id, 
            status: \$status, 
            deliveredAt: \$deliveredAt
          }) {
            id
            status
          }
        }
      ''';

      final operation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: graphQLDocument,
          variables: {
            'id': pkg.id,
            'status': 'DELIVERED',
            'deliveredAt': TemporalDateTime.now().toString(),
          },
          authorizationMode: APIAuthorizationType.apiKey,
        ),
      );

      final response = await operation.response;

      if (response.hasErrors) {
        throw Exception(response.errors.first.message);
      }

      print("✅ Paquete entregado (Backend confirmado).");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Entregado correctamente"), backgroundColor: Colors.green)
        );
        // Recargamos la lista para que desaparezca visualmente
        _loadPackagesForApt(_selectedApartment!);
      }

    } catch (e) {
      print("Error entregando: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entregar Paquetes"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Column(
        children: [
          // FILTROS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTower,
                  decoration: const InputDecoration(labelText: "Torre", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  items: _towers.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: _onTowerChanged,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Apartment>(
                  value: _selectedApartment,
                  decoration: const InputDecoration(labelText: "Apartamento", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  items: _selectedTower == null ? [] : _unitsInTower.map((u) => DropdownMenuItem(value: u, child: Text(u.unitNumber))).toList(),
                  onChanged: (val) {
                    if (val != null) _loadPackagesForApt(val);
                  },
                  hint: Text(_selectedTower == null ? "Primero Torre" : "Selecciona Apto"),
                ),
              ],
            ),
          ),

          // LISTA DE RESULTADOS
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _selectedApartment == null 
                  ? const Center(child: Text("Selecciona un apartamento para buscar", style: TextStyle(color: Colors.grey)))
                  : _pendingPackages.isEmpty
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("No hay nada pendiente por aquí", style: TextStyle(fontSize: 16, color: Colors.grey))
                          ],
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingPackages.length,
                          itemBuilder: (context, index) {
                            final pkg = _pendingPackages[index];
                            final date = pkg.receivedAt.getDateTimeInUtc().toLocal();
                            
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const Icon(Icons.inventory_2, color: Colors.teal, size: 30),
                                title: Text(pkg.courier, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Para: ${pkg.recipient?.username ?? 'Vecino'}\nLlegó: ${date.day}/${date.month} ${date.hour}:${date.minute}"),
                                trailing: ElevatedButton(
                                  onPressed: () => _markAsDelivered(pkg),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                                  child: const Text("ENTREGAR"),
                                ),
                              ),
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }
}