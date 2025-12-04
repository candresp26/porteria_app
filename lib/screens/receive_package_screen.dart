import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';

class ReceivePackageScreen extends StatefulWidget {
  const ReceivePackageScreen({super.key});

  @override
  State<ReceivePackageScreen> createState() => _ReceivePackageScreenState();
}

class _ReceivePackageScreenState extends State<ReceivePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courierController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true; // Para mostrar carga al inicio

  // --- VARIABLES PARA LOS DROPDOWNS ---
  List<Apartment> _allApartments = []; // Todos los aptos de la BD
  List<String> _towers = []; // Lista de nombres de torres únicas
  List<Apartment> _unitsInTower = []; // Aptos filtrados por torre seleccionada

  String? _selectedTower;
  Apartment? _selectedApartment;

  @override
  void initState() {
    super.initState();
    _loadApartments(); // Cargar datos apenas abre la pantalla
  }

  // 1. CARGAR DATOS MAESTROS
  Future<void> _loadApartments() async {
    try {
      // Pedimos todos los apartamentos
      final request = ModelQueries.list(
        Apartment.classType, 
        authorizationMode: APIAuthorizationType.apiKey
      );
      final response = await Amplify.API.query(request: request).response;
      
      if (response.data != null) {
        setState(() {
          _allApartments = response.data!.items.whereType<Apartment>().toList();
          
          // Magia: Extraer nombres de torres únicos y ordenarlos
          _towers = _allApartments.map((a) => a.tower).toSet().toList();
          _towers.sort(); // Orden alfabético (Torre 1, Torre 2...)
          
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print("Error cargando apartamentos: $e");
      setState(() => _isLoadingData = false);
    }
  }

  // 2. FILTRAR APTOS CUANDO SELECCIONA TORRE
  void _onTowerChanged(String? newTower) {
    if (newTower == null) return;
    setState(() {
      _selectedTower = newTower;
      _selectedApartment = null; // Resetear apto seleccionado
      
      // Filtrar aptos que pertenecen a esta torre y ordenarlos por número
      _unitsInTower = _allApartments.where((a) => a.tower == newTower).toList();
      _unitsInTower.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    });
  }

Future<void> _registerPackage() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedApartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona Torre y Apartamento')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("📦 Iniciando registro blindado...");

      // 1. Buscar Usuario (Igual que antes)
      final userReq = ModelQueries.list(User.classType, authorizationMode: APIAuthorizationType.apiKey);
      final userRes = await Amplify.API.query(request: userReq).response;
      
      if (userRes.data == null) throw Exception("Error consultando usuarios.");

      final residents = userRes.data!.items.where(
        (u) => u?.apartment?.id == _selectedApartment!.id
      ).toList();

      if (residents.isEmpty) throw Exception("No hay residentes en este apartamento.");
      
      final destinatario = residents.first!;

      // 2. MUTACIÓN MANUAL (FRANCOTIRADOR)
      // Escribimos la petición nosotros mismos para controlar qué nos devuelve AWS.
      // Solo pedimos 'id' y 'courier' de vuelta. NO pedimos 'recipient'.
      
      const graphQLDocument = '''
        mutation CreatePackage(\$courier: String!, \$recipientID: ID!, \$status: PackageStatus!, \$receivedAt: AWSDateTime!, \$photoKey: String) {
          createPackage(input: {
            courier: \$courier, 
            recipientID: \$recipientID, 
            status: \$status, 
            receivedAt: \$receivedAt,
            photoKey: \$photoKey
          }) {
            id
            courier
          }
        }
      ''';

      final operation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: graphQLDocument,
          variables: {
            'courier': _courierController.text.trim(),
            'recipientID': destinatario.id, // Pasamos el ID explícito aquí
            'status': 'IN_WAREHOUSE', // El enum como String
            'receivedAt': TemporalDateTime.now().toString(),
            'photoKey': 'foto_pendiente.jpg'
          },
          authorizationMode: APIAuthorizationType.apiKey,
        ),
      );

      final response = await operation.response;

      if (response.hasErrors) {
        throw Exception(response.errors.first.message);
      }

      print("✅ Paquete creado con ID: ${response.data}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📦 Paquete registrado exitosamente'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); 
      }

    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recibir Paquete"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.orange),
                const SizedBox(height: 20),
                
                // --- DROPDOWN 1: TORRE ---
                DropdownButtonFormField<String>(
                  value: _selectedTower,
                  decoration: const InputDecoration(labelText: "Selecciona Torre", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                  items: _towers.map((tower) {
                    return DropdownMenuItem(value: tower, child: Text(tower));
                  }).toList(),
                  onChanged: _onTowerChanged,
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
                
                const SizedBox(height: 20),

                // --- DROPDOWN 2: APARTAMENTO ---
                // Solo se activa si ya seleccionó torre
                DropdownButtonFormField<Apartment>(
                  value: _selectedApartment,
                  decoration: const InputDecoration(labelText: "Selecciona Apartamento", border: OutlineInputBorder(), prefixIcon: Icon(Icons.door_front_door)),
                  // Si no hay torre, el menú está vacío y deshabilitado
                  items: _selectedTower == null ? [] : _unitsInTower.map((apto) {
                    return DropdownMenuItem(value: apto, child: Text(apto.unitNumber));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedApartment = val),
                  validator: (v) => v == null ? 'Requerido' : null,
                  hint: Text(_selectedTower == null ? "Primero elige una torre" : "Elige un apto"),
                ),

                const SizedBox(height: 20),

                // Empresa
                TextFormField(
                  controller: _courierController,
                  decoration: const InputDecoration(labelText: "Empresa Transportadora", prefixIcon: Icon(Icons.local_shipping), border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerPackage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("GUARDAR PAQUETE"),
                  ),
                )
              ],
            ),
          ),
        ),
    );
  }
}