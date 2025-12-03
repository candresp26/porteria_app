import 'package:flutter/material.dart';
// 1. Imports de AWS y Modelos
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart'; // Asegúrate de que esta ruta a tus modelos sea correcta

// 2. Imports para Navegación y Persistencia
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // 1. Validar visualmente (campos rojos si están vacíos)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final codigoIngresado = _codeController.text.trim();
    final celularIngresado = _phoneController.text.trim();

    try {
      // 2. PREGUNTAR A AWS: ¿Existe este apartamento?
      // IMPORTANTE: Usamos 'authorizationMode: APIAuthorizationType.apiKey' 
      // para permitir la búsqueda sin estar logueado aún.
      final request = ModelQueries.list(
        Apartment.classType,
        where: Apartment.ACCESSCODE.eq(codigoIngresado),
        authorizationMode: APIAuthorizationType.apiKey, 
      );

      final response = await Amplify.API.query(request: request).response;
      
      // Logs para depuración (puedes borrarlos luego)
      print("📦 DATOS CRUDOS: ${response.data?.items.firstOrNull.toString()}");
      if (response.errors.isNotEmpty) {
        print("🚨 ERRORES GRAPHQL: ${response.errors}");
      }

      final data = response.data;

      if (data == null || response.errors.isNotEmpty) {
        throw Exception("Error leyendo datos de AWS: ${response.errors.firstOrNull?.message}");
      }

      // 3. VERIFICAR RESULTADOS
      if (data.items.isEmpty) {
        // El código NO existe en la base de datos
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⛔ Código incorrecto. Verifica e intenta de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // ¡EUREKA! El código existe
        final apartamentoEncontrado = data.items.first;
        
        // 4. GUARDAR SESIÓN Y NAVEGAR
        if (apartamentoEncontrado != null) {
          final prefs = await SharedPreferences.getInstance();
          
          // Guardamos datos en el celular
          await prefs.setString('tower', apartamentoEncontrado.tower);
          await prefs.setString('unit', apartamentoEncontrado.unitNumber);
          await prefs.setString('userPhone', celularIngresado); // Guardamos el celular también
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ¡Bienvenido! Apto: ${apartamentoEncontrado.unitNumber}'),
                backgroundColor: Colors.green,
              ),
            );

            // Redirigir al Home (y borrar el Login del historial para no volver atrás)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  tower: apartamentoEncontrado.tower,
                  unit: apartamentoEncontrado.unitNumber,
                ),
              ),
            );
          }
        }
      }

    } on Exception catch (e) {
      safePrint('Error técnico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      // Siempre apagar el círculo de carga
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              
              const Text(
                'Bienvenido',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const Text(
                'Control de Portería',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey, // Asignamos la llave del formulario
                    child: Column(
                      children: [
                        // Input: Celular
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Número de Celular',
                            prefixIcon: Icon(Icons.phone_android),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu celular';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Input: Código de Apto
                        TextFormField(
                          controller: _codeController,
                          obscureText: true, // Ocultar texto
                          decoration: const InputDecoration(
                            labelText: 'Código de Apartamento',
                            prefixIcon: Icon(Icons.vpn_key),
                            border: OutlineInputBorder(),
                            helperText: 'Ej: DEMO-123',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El código es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Botón de Ingreso
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('INGRESAR', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}