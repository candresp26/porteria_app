import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart'; // Esto importa Apartment y ApartmentModelIdentifier
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'guard_screen.dart';
import 'change_password_screen.dart';

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

  Future<void> _smartLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final username = _userController.text.trim();
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
                
                // CORRECCIÓN APLICADA AQUÍ: Usamos ApartmentModelIdentifier
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
        // === USUARIO NUEVO (Auto-registro Vecino) ===
        final requestApto = ModelQueries.list(
          Apartment.classType,
          where: Apartment.ACCESSCODE.eq(password),
          authorizationMode: APIAuthorizationType.apiKey,
        );
        final responseApto = await Amplify.API.query(request: requestApto).response;

        if (responseApto.data == null || responseApto.data!.items.isEmpty) {
          throw Exception("Usuario no existe y el código no es de ningún apartamento.");
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
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GuardScreen()));
      } else {
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
                    if (v == null || v.length < 5) return 'Mínimo 5 caracteres';
                    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) return 'Solo letras y números';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña o Código', border: OutlineInputBorder(), prefixIcon: Icon(Icons.key)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(onPressed: _isLoading ? null : _smartLogin, child: const Text("INGRESAR")),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}