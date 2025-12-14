import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports de tus pantallas y modelos
import '../models/ModelProvider.dart';
import 'home_screen.dart';
import 'guard_home_screen.dart'; // El menú del portero
import 'change_password_screen.dart';

// 👇 IMPORTANTE: Importamos el sembrador de datos
import '../utils/seeder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  bool _obscurePassword = true;

  Future<void> _smartLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final username = _userController.text.trim().toLowerCase(); // Forzamos minúsculas
    final password = _passController.text.trim();

    try {
      // 1. BUSCAR USUARIO POR USERNAME
      final requestUser = ModelQueries.list(
        User.classType,
        where: User.USERNAME.eq(username),
        authorizationMode: APIAuthorizationType.apiKey,
      );
      final responseUser = await Amplify.API.query(request: requestUser).response;
      final existingUser = responseUser.data?.items.firstOrNull;

      if (existingUser != null) {
        // === USUARIO YA EXISTE ===
        if (existingUser.password == password) {
          
          if (existingUser.isFirstLogin) {
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(user: existingUser)
              ));
            }
          } else {
            // --> CASO: USUARIO RECURRENTE
             Apartment? aptoData;
             
             if (existingUser.apartment != null) {
               final aptId = existingUser.apartment!.id; 
               final aptReq = ModelQueries.get(
                 Apartment.classType, 
                 ApartmentModelIdentifier(id: aptId), 
                 authorizationMode: APIAuthorizationType.apiKey
               );
               final aptRes = await Amplify.API.query(request: aptReq).response;
               aptoData = aptRes.data;
             }
             await _saveSessionAndNavigate(existingUser, aptoData);
          }

        } else {
          throw Exception("Contraseña incorrecta.");
        }

      } else {
        // === USUARIO NUEVO (Auto-registro con código de apartamento) ===
        // Buscamos si lo que ingresó en "password" es un código de acceso de apto
        final requestApto = ModelQueries.list(
          Apartment.classType,
          where: Apartment.ACCESSCODE.eq(password),
          authorizationMode: APIAuthorizationType.apiKey,
        );
        final responseApto = await Amplify.API.query(request: requestApto).response;

        if (responseApto.data == null || responseApto.data!.items.isEmpty) {
          throw Exception("Usuario no encontrado y el código no pertenece a ningún apartamento.");
        }

        final apartamento = responseApto.data!.items.first!;
        
        final newUser = User(
          username: username,
          password: password,
          isFirstLogin: true,
          role: Role.RESIDENT,
          apartment: apartamento,
          name: "Vecino",
        );

        final createReq = ModelMutations.create(newUser, authorizationMode: APIAuthorizationType.apiKey);
        final createRes = await Amplify.API.mutate(request: createReq).response;

        if (createRes.data != null) {
          if (mounted) {
             final userWithData = (createRes.data as User).copyWith(
               apartment: apartamento
             );

             Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(user: userWithData)
              ));
          }
        } else {
          throw Exception("Error creando usuario.");
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('⛔ ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSessionAndNavigate(User user, Apartment? apto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setString('username', user.username);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userRole', user.role.name); 

    if (apto != null) {
      await prefs.setString('tower', apto.tower);
      await prefs.setString('unit', apto.unitNumber);
    }

    if (mounted) {
      if (user.role == Role.GUARD || user.role == Role.ADMIN) {
         // Redirige al Menú del Portero
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GuardHomeScreen()));
      } else {
         // Redirige al Home del Vecino
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(
             tower: apto?.tower ?? "", unit: apto?.unitNumber ?? ""
         )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.shield, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                const Text('Portería App', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: 'Usuario Único', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  validator: (v) {
                    if (v == null || v.length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
TextFormField(
                  controller: _passController,
                  obscureText: _obscurePassword, // 👈 Usamos la variable
                  decoration: InputDecoration(
                    labelText: 'Contraseña o Código', 
                    border: const OutlineInputBorder(), 
                    prefixIcon: const Icon(Icons.key),
                    // 👇 BOTÓN DEL OJO
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword; // Alternar
                        });
                      },
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(onPressed: _isLoading ? null : _smartLogin, child: const Text("INGRESAR")),
                ),

                // 👇👇👇 AQUÍ ESTÁN LOS BOTONES DE SEMBRAR DATOS 👇👇👇
                const SizedBox(height: 40),
                const Divider(),
                const Text("HERRAMIENTAS DEV (Solo pruebas)", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón 1: Crear Aptos
                    TextButton.icon(
                      icon: const Icon(Icons.domain_add),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🌱 Creando Aptos... (Mira la consola)")));
                        await DataSeeder.sembrarApartamentos();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Apartamentos listos")));
                      },
                      label: const Text("1. Sembrar Aptos"),
                    ),
                    // Botón 2: Crear Usuarios
                    TextButton.icon(
                      icon: const Icon(Icons.person_add),
                      onPressed: () async {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("👤 Creando Vecinos... (Mira la consola)")));
                         await DataSeeder.sembrarUsuarios();
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Vecinos listos")));
                      },
                      label: const Text("2. Sembrar Usuarios"),
                    ),
                  ],
                ),
                // 👆👆👆 FIN BOTONES DEV 👆👆👆
              ],
            ),
          ),
        ),
      ),
    );
  }
}