import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart'; // Verifica que la ruta sea correcta

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controladores
  final _usernameController = TextEditingController(); 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _accessCodeController = TextEditingController(); 

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Datos Dropdowns
  List<Apartment> _allApartments = [];
  List<String> _towers = [];
  List<Apartment> _unitsInTower = [];
  String? _selectedTower;
  Apartment? _selectedApartment;

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  Future<void> _loadApartments() async {
    try {
      print("🏢 [SignUp] Cargando lista de apartamentos...");
      
      final request = ModelQueries.list(
        Apartment.classType, 
        authorizationMode: APIAuthorizationType.apiKey
      );
      
      final response = await Amplify.API.query(request: request).response;
      
      if (response.hasErrors) {
        print("❌ Error GraphQL: ${response.errors.first.message}");
        return;
      }

      final rawList = response.data?.items ?? [];
      final validList = rawList.whereType<Apartment>().toList();

      if (response.data != null) {
        setState(() {
          _allApartments = validList;
          _towers = _allApartments.map((a) => a.tower).toSet().toList();
          _towers.sort();
        });
      }
    } catch (e) {
      print("🔥 Error grave cargando aptos: $e");
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

  Future<void> _registerUser() async {
    // 1. Validaciones Básicas
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      _showError("Todos los campos son obligatorios");
      return;
    }
    
    if (_passwordController.text.length < 8) {
      _showError("La contraseña debe tener al menos 8 caracteres.");
      return;
    }
    if (_selectedApartment == null) {
      _showError("Selecciona tu apartamento");
      return;
    }
    if (_accessCodeController.text.isEmpty) {
      _showError("Ingresa el código de acceso");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. VERIFICAR APARTAMENTO (Seguridad y Capacidad)
      final aptReq = ModelQueries.get(
        Apartment.classType, 
        ApartmentModelIdentifier(id: _selectedApartment!.id),
        authorizationMode: APIAuthorizationType.apiKey
      );
      final aptRes = await Amplify.API.query(request: aptReq).response;
      if (aptRes.data == null) throw Exception("Error consultando el apartamento.");
      final freshApt = aptRes.data!;

      // Validar Código de Acceso
      if (_accessCodeController.text.trim() != freshApt.accessCode) {
        throw Exception("🚫 Código incorrecto.");
      }
      
      // Validar Vencimiento
      if (freshApt.codeExpiresAt != null) {
        final expiration = DateTime.parse(freshApt.codeExpiresAt.toString());
        if (DateTime.now().isAfter(expiration)) throw Exception("⏳ Código vencido.");
      }
      
      // --- VALIDACIÓN DE CUPO DINÁMICA ---
      final usersReq = ModelQueries.list(User.classType, where: User.APARTMENT.eq(freshApt.id));
      final usersRes = await Amplify.API.query(
        request: GraphQLRequest<PaginatedResult<User>>(
          document: usersReq.document,
          variables: usersReq.variables,
          modelType: usersReq.modelType,
          decodePath: usersReq.decodePath,
          authorizationMode: APIAuthorizationType.apiKey
        )
      ).response;
      
      final currentResidents = usersRes.data?.items.length ?? 0;
      
      // AQUI ES EL CAMBIO: Leemos la capacidad real de la BD (si es null, usa 3)
      final int maxCapacity = freshApt.maxResidents ?? 3; 
      
      if (currentResidents >= maxCapacity) {
        throw Exception("🔒 Cupo lleno. Este apartamento solo permite $maxCapacity residentes.");
      }
      // ------------------------------------

      // 3. REGISTRO EN AWS COGNITO
      final userAttributes = {
        AuthUserAttributeKey.email: _emailController.text.trim(),
        AuthUserAttributeKey.name: _nameController.text.trim(),
      };

      final result = await Amplify.Auth.signUp(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        options: SignUpOptions(userAttributes: userAttributes),
      );

      // 4. GUARDAR EN BD
      if (result.isSignUpComplete) {
          await _createUserInDB(result.userId ?? "temp-id");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ¡Bienvenido!"), backgroundColor: Colors.green));
            Navigator.pop(context); 
          }
      } else {
        if (mounted) _showConfirmationDialog(); 
      }

    } catch (e) {
      _showError(e.toString().replaceAll("Exception:", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _createUserInDB(String authUserId) async {
    print("🕵️ INICIO: Intentando guardar usuario en DynamoDB...");
    
    // 1. Crear objeto Usuario (Incluimos isActive por seguridad)
    final newUser = User(
      id: authUserId,
      username: _usernameController.text.trim(),
      isFirstLogin: true,
      role: Role.RESIDENT,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      tower: _selectedTower,
      unit: _selectedApartment!.unitNumber,
      apartment: _selectedApartment,
      isActive: true, // <--- NUEVO: Aseguramos que nazca activo
    );

    // 2. Crear la petición
    final request = ModelMutations.create(newUser);

    // 3. Configurar autorización Pública (API Key)
    final requestWithAuth = GraphQLRequest<User>(
      document: request.document,
      variables: request.variables,
      modelType: request.modelType,
      decodePath: request.decodePath,
      authorizationMode: APIAuthorizationType.apiKey, // Forzamos llave pública
    );

    // 4. Enviar y VERIFICAR ERRORES
    final response = await Amplify.API.mutate(request: requestWithAuth).response;

    if (response.hasErrors) {
      // AQUÍ ESTABA EL PROBLEMA ANTES: Ignorábamos los errores
      final errorMsg = response.errors.first.message;
      print("🔥 ERROR FATAL DYNAMODB: $errorMsg");
      throw Exception("No se pudo guardar en base de datos: $errorMsg");
    } else {
      print("✅ ¡ÉXITO! Usuario guardado en DynamoDB.");
    }
  }
  
  void _showConfirmationDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Verifica tu correo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enviamos un código a ${_emailController.text}"),
            const SizedBox(height: 10),
            TextField(
              controller: codeController, 
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "Código de 6 dígitos", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              try {
                final res = await Amplify.Auth.confirmSignUp(
                  username: _usernameController.text.trim(),
                  confirmationCode: codeController.text.trim()
                );
                if (res.isSignUpComplete) {
                  await _createUserInDB("${DateTime.now().millisecondsSinceEpoch}");
                  if (mounted) {
                    Navigator.pop(ctx); 
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Cuenta creada. Inicia sesión."), backgroundColor: Colors.green));
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
              }
            },
            child: const Text("Confirmar"),
          )
        ],
      )
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 50, color: Colors.indigo),
            const SizedBox(height: 20),
            
            TextField(
              controller: _usernameController, 
              decoration: const InputDecoration(
                labelText: "Usuario", 
                hintText: "Ej: luisa.perez",
                prefixIcon: Icon(Icons.account_circle), 
                border: OutlineInputBorder()
              )
            ),
            const SizedBox(height: 15),

            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Correo Electrónico", prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            TextField(
              controller: _passwordController, 
              obscureText: !_isPasswordVisible, 
              decoration: InputDecoration(
                labelText: "Contraseña", 
                prefixIcon: const Icon(Icons.lock), 
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off), onPressed: ()=>setState(()=>_isPasswordVisible=!_isPasswordVisible))
              )
            ),
            const SizedBox(height: 15),
            
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre Completo", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
            const SizedBox(height: 25),
            
            // DATOS APTO
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                children: [
                   const Text("Tu Vivienda", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                   const SizedBox(height: 10),
                   Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTower,
                          isExpanded: true,
                          items: _towers.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: _onTowerChanged,
                          decoration: const InputDecoration(labelText: "Torre", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<Apartment>(
                          value: _selectedApartment,
                          isExpanded: true,
                          items: _unitsInTower.map((u) => DropdownMenuItem(value: u, child: Text(u.unitNumber))).toList(),
                          onChanged: (val) => setState(() => _selectedApartment = val),
                          decoration: const InputDecoration(labelText: "Apto", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _accessCodeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: "CÓDIGO DE ACCESO", hintText: "Ej: ADMIN2025", border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CREAR CUENTA"),
              ),
            )
          ],
        ),
      ),
    );
  }
}