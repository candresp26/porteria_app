import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../models/ModelProvider.dart';

class ReceivePackageScreen extends StatefulWidget {
  const ReceivePackageScreen({super.key});

  @override
  State<ReceivePackageScreen> createState() => _ReceivePackageScreenState();
}

class _ReceivePackageScreenState extends State<ReceivePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courierController = TextEditingController();
  
  // Variables para Dropdowns
  List<Apartment> _allApartments = [];
  List<String> _towers = [];
  List<Apartment> _unitsInTower = [];
  String? _selectedTower;
  Apartment? _selectedApartment;

  bool _isLoading = false;
  bool _isLoadingData = true;

  // VARIABLES PARA LA CÁMARA 📸
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile; 

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  // Carga de datos inicial
  Future<void> _loadApartments() async {
    try {
      final request = ModelQueries.list(Apartment.classType, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.query(request: request).response;
      if (response.data != null) {
        setState(() {
          _allApartments = response.data!.items.whereType<Apartment>().toList();
          _towers = _allApartments.map((a) => a.tower).toSet().toList();
          _towers.sort();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print("Error cargando aptos: $e");
      setState(() => _isLoadingData = false);
    }
  }

  void _onTowerChanged(String? newTower) {
    if (newTower == null) return;
    setState(() {
      _selectedTower = newTower;
      _selectedApartment = null;
      _unitsInTower = _allApartments.where((a) => a.tower == newTower).toList();
      _unitsInTower.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    });
  }

  // 📸 FUNCIÓN 1: ABRIR CÁMARA
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50, // Comprimimos para optimizar
      );
      
      if (photo != null) {
        setState(() {
          _imageFile = photo;
        });
      }
    } catch (e) {
      print("Error tomando foto: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cámara: $e")));
    }
  }

// ☁️ FUNCIÓN 2: SUBIR A S3 (Versión corregida con prefijo 'public/')
  Future<String?> _uploadPhotoToS3() async {
    if (_imageFile == null) return null;
    
    if (_selectedTower == null || _selectedApartment == null) {
       throw Exception("Selecciona Torre y Apartamento antes de subir la foto.");
    }
    
    try {
      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final year = now.year.toString();
      final fechaString = "$day$month$year";
      
      final towerName = _selectedTower!; 
      final unitNumber = _selectedApartment!.unitNumber; 
      final uniqueId = now.millisecondsSinceEpoch.toString();

      final filename = "PKT-$fechaString-$unitNumber-$uniqueId.jpg";

      // CORRECCIÓN DE SEGURIDAD:
      // AWS exige que los archivos de acceso "Guest" estén dentro de 'public/'
      final fullPath = "public/$towerName/$unitNumber/$filename";
      
      final file = File(_imageFile!.path);

      print("📂 Subiendo a ruta segura: $fullPath");

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        path: StoragePath.fromString(fullPath), 
        onProgress: (progress) {
          print("Subiendo: ${progress.fractionCompleted * 100}%");
        }
      ).result;

      return uploadResult.uploadedItem.path; 
      
    } catch (e) {
      print("Error subiendo a S3: $e");
      // Importante: Lanzamos el error original para ver detalles si falla de nuevo
      throw Exception("AWS rechazó el archivo: ${e.toString()}");
    }
  }

  Future<void> _registerPackage() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedApartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona Torre y Apartamento')));
      return;
    }

    // Validación opcional: Obligar foto
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📸 ¡Falta la foto del paquete!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Subir Foto primero (Organizada por carpetas)
      print("📸 Subiendo foto...");
      final photoKey = await _uploadPhotoToS3();
      print("✅ Foto subida: $photoKey");

      // 2. Buscar Destinatario (Estrategia robusta)
      final userReq = ModelQueries.list(User.classType, authorizationMode: APIAuthorizationType.apiKey);
      final userRes = await Amplify.API.query(request: userReq).response;
      
      // Filtramos en memoria
      final residents = userRes.data!.items.whereType<User>().where(
        (u) => u.apartment?.id == _selectedApartment!.id
      ).toList();

      if (residents.isEmpty) throw Exception("No hay residentes en este apartamento.");
      final destinatario = residents.first;

      // 3. Crear Paquete (Mutación Manual para evitar errores de permisos)
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
            photoKey
          }
        }
      ''';

      final operation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: graphQLDocument,
          variables: {
            'courier': _courierController.text.trim(),
            'recipientID': destinatario.id,
            'status': 'IN_WAREHOUSE',
            'receivedAt': TemporalDateTime.now().toString(),
            'photoKey': photoKey, 
          },
          authorizationMode: APIAuthorizationType.apiKey,
        ),
      );

      final response = await operation.response;
      if (response.hasErrors) throw Exception(response.errors.first.message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📦 Paquete registrado con FOTO!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }

    } catch (e) {
      print("Error: $e");
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
      appBar: AppBar(title: const Text("Recibir Paquete"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // --- CÁMARA ---
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade400),
                      image: _imageFile != null 
                        ? DecorationImage(
                            image: FileImage(File(_imageFile!.path)),
                            fit: BoxFit.cover
                          )
                        : null
                    ),
                    child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            Text("Tocar para tomar foto", style: TextStyle(color: Colors.grey))
                          ],
                        )
                      : null,
                  ),
                ),
                if (_imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      onPressed: _takePhoto, 
                      icon: const Icon(Icons.refresh), 
                      label: const Text("Cambiar foto")
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Dropdowns
                DropdownButtonFormField<String>(
                  value: _selectedTower,
                  decoration: const InputDecoration(labelText: "Torre", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                  items: _towers.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: _onTowerChanged,
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<Apartment>(
                  value: _selectedApartment,
                  decoration: const InputDecoration(labelText: "Apartamento", border: OutlineInputBorder(), prefixIcon: Icon(Icons.door_front_door)),
                  items: _selectedTower == null ? [] : _unitsInTower.map((u) => DropdownMenuItem(value: u, child: Text(u.unitNumber))).toList(),
                  onChanged: (val) => setState(() => _selectedApartment = val),
                  validator: (v) => v == null ? 'Requerido' : null,
                  hint: Text(_selectedTower == null ? "Primero Torre" : "Selecciona Apto"),
                ),
                const SizedBox(height: 15),

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
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 10),
                            Text("Subiendo foto...")
                          ],
                        )
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