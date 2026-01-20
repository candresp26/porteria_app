import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'guard_screen.dart';
import 'guard_home_screen.dart'; 

class ChangePasswordScreen extends StatefulWidget {
  final User user;
  const ChangePasswordScreen({super.key, required this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      print("🔒 Operación Francotirador: Actualizando solo contraseña...");

      // 1. DEFINIMOS LA MUTACIÓN MANUALMENTE
      // Esto asegura que NO toquemos el campo 'name' ni 'apartment'
      const graphQLDocument = '''
        mutation UpdateUserPassword(\$id: ID!, \$password: String!, \$isFirstLogin: Boolean!) {
          updateUser(input: {id: \$id, password: \$password, isFirstLogin: \$isFirstLogin}) {
            id
            username
            isFirstLogin
          }
        }
      ''';

      // 2. EJECUTAMOS LA PETICIÓN
      final operation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: graphQLDocument,
          variables: {
            'id': widget.user.id,
            'password': _newPassController.text.trim(),
            'isFirstLogin': false,
          },
          authorizationMode: APIAuthorizationType.apiKey, // Usamos la llave pública
        ),
      );

      final response = await operation.response;

      if (response.hasErrors) {
        throw Exception("AWS Error: ${response.errors.first.message}");
      }

      print("✅ Contraseña blindada actualizada.");

      // 3. NAVEGACIÓN (Usando los datos que ya tenemos en memoria)
      final finalUser = widget.user.copyWith(
        password: _newPassController.text.trim(),
        isFirstLogin: false
      );
      
      await _saveAndNavigate(finalUser);

    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}"), 
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _saveAndNavigate(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('userRole', user.role.name);
    await prefs.setBool('isLoggedIn', true);

    final apto = user.apartment ?? widget.user.apartment;

    if (apto != null) {
      await prefs.setString('tower', apto.tower);
      await prefs.setString('unit', apto.unitNumber);
    }

    if (!mounted) return;
    
    if (user.role == Role.GUARD || user.role == Role.ADMIN) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const GuardHomeScreen()), 
        (route) => false
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => HomeScreen(
          tower: apto?.tower ?? "", 
          unit: apto?.unitNumber ?? ""
        )),
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurar Seguridad"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.lock_reset, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Seguridad Primero", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 10),
              
              Text(
                "Crea una contraseña personal para proteger tu cuenta.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]), 
              ),
              
              const SizedBox(height: 30),

              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Nueva Contraseña", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock)
                ),
                validator: (v) {
                  if (v == null || v.length < 5) return "Mínimo 5 caracteres";
                  final alphaNumeric = RegExp(r'^[a-zA-Z0-9]+$');
                  if (!alphaNumeric.hasMatch(v)) return "Solo letras y números";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirmar Contraseña", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline)
                ),
                validator: (v) {
                  if (v != _newPassController.text) return "Las contraseñas no coinciden";
                  return null;
                },
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("GUARDAR Y ENTRAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}