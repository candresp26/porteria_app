import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../models/ModelProvider.dart';
import '../widgets/guard_pin_dialog.dart';

class ReceivePackageScreen extends StatefulWidget {
  const ReceivePackageScreen({super.key});

  @override
  State<ReceivePackageScreen> createState() => _ReceivePackageScreenState();
}

class _ReceivePackageScreenState extends State<ReceivePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courierController = TextEditingController();
  
  List<Apartment> _allApartments = [];
  List<String> _towers = [];
  List<Apartment> _unitsInTower = [];
  String? _selectedTower;
  Apartment? _selectedApartment;

  bool _isLoading = false;
  bool _isLoadingData = true;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile; 

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        // 👇 OPTIMIZACIÓN CRÍTICA PARA SAMSUNG S23 Y CELULARES MODERNOS 👇
        imageQuality: 50,      
        maxWidth: 1024,        
      );
      
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        print("📸 Foto lista. Tamaño: ${(bytes.length / 1024).toStringAsFixed(2)} KB");

        setState(() {
          _imageFile = photo;
        });
      }
    } catch (e) {
      print("Error tomando foto: $e");
    }
  }

  Future<String?> _uploadPhotoToS3() async {
    if (_imageFile == null) return null;
    if (_selectedTower == null || _selectedApartment == null) throw Exception("Faltan datos de torre/apto");
    
    try {
      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final year = now.year.toString();
      final fechaString = "$day$month$year";
      
      final towerName = _selectedTower!; 
      final unitNumber = _selectedApartment!.unitNumber; 
      final uniqueId = now.millisecondsSinceEpoch.toString();

      // Estructura: public/Torre/Apto/Foto.jpg
      final filename = "PKT-$fechaString-$unitNumber-$uniqueId.jpg";
      final fullPath = "public/$towerName/$unitNumber/$filename";
      final file = File(_imageFile!.path);

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        path: StoragePath.fromString(fullPath), 
      ).result;

      return uploadResult.uploadedItem.path; 
    } catch (e) {
      print("Error subiendo a S3: $e");
      throw Exception("Error subiendo foto: ${e.toString()}");
    }
  }

  Future<void> _registerPackage() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedApartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona Torre y Apartamento')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📸 ¡Falta la foto del paquete!')));
      return;
    }

    // 1. Validaciones OK, pedimos PIN
    final String? guardName = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GuardPinDialog(action: "Registrar"),
    );

    if (guardName == null) return;

    setState(() => _isLoading = true);

    try {
      // 2. Subir Foto
      print("🚀 Subiendo foto a S3...");
      final photoKey = await _uploadPhotoToS3();
      print("✅ Foto subida: $photoKey");

   // 3. Buscar Destinatario (CORREGIDO CON API KEY)
      print("🔍 Buscando residentes en Torre: $_selectedTower, Apto: ${_selectedApartment!.unitNumber}");
      
      final requestUsers = ModelQueries.list(
        User.classType,
        // Buscamos coincidencia exacta de Torre y Unidad
        where: User.TOWER.eq(_selectedTower).and(User.UNIT.eq(_selectedApartment!.unitNumber)),
        // 👇👇 LA LÍNEA MÁGICA QUE ARREGLA EL "0 RESULTADOS" 👇👇
        authorizationMode: APIAuthorizationType.apiKey  
      );
      
      final responseUsers = await Amplify.API.query(request: requestUsers).response;
      
      // Verificamos si hubo errores de seguridad
      if (responseUsers.hasErrors) {
         print("❌ Error de Permisos: ${responseUsers.errors.first.message}");
         throw Exception("Error de permisos: ${responseUsers.errors.first.message}");
      }

      final residents = responseUsers.data?.items;
      print("📊 Residentes encontrados: ${residents?.length ?? 0}");

      if (residents == null || residents.isEmpty) {
        throw Exception("No hay residentes registrados en Torre $_selectedTower - ${_selectedApartment!.unitNumber}");
      }

      // Tomamos el primero (usamos whereType para evitar nulos)
      final destinatario = residents.whereType<User>().first;
      print("✅ Destinatario: ${destinatario.name}");

// 4. Crear Paquete
      print("📦 Preparando creación del paquete...");
      
      final newPackage = Package(
        courier: _courierController.text.trim(),
        recipient: destinatario,  
        status: PackageStatus.IN_WAREHOUSE,
        receivedAt: TemporalDateTime.now(),
        photoKey: photoKey,
        receivedBy: guardName,
      );

      // 👇 CAMBIO FINAL: Usamos apiKey porque tu base de datos es pública
      final requestCreate = ModelMutations.create(
        newPackage, 
        authorizationMode: APIAuthorizationType.apiKey 
      );
      
      final responseCreate = await Amplify.API.mutate(request: requestCreate).response;

      if (responseCreate.hasErrors) {
        print("❌ Error GraphQL: ${responseCreate.errors.first.message}");
        throw Exception("Error creando paquete: ${responseCreate.errors.first.message}");
      }

      print("🎉 ¡PAQUETE GUARDADO! ID: ${newPackage.id}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📦 Registrado por $guardName'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); 
      }

    } catch (e) {
      print("🔥 Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
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
                // CÁMARA
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
                
                // DROPDOWNS
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

                // EMPRESA
                TextFormField(
                  controller: _courierController,
                  decoration: const InputDecoration(labelText: "Empresa Transportadora", prefixIcon: Icon(Icons.local_shipping), border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 30),

                // BOTÓN
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
                            Text("Guardando...")
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