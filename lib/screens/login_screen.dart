import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Clave global para identificar el formulario y validarlo
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() {
    // 2. Antes de hacer nada, preguntamos: ¿El formulario es válido?
    if (_formKey.currentState!.validate()) {
      // Si todo está bien, procedemos
      setState(() {
        _isLoading = true;
      });

      print("📞 Celular: ${_phoneController.text}");
      print("🔑 Código: ${_codeController.text}");

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Datos válidos. Conectando con AWS...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } else {
      // Si hay errores, no hacemos nada (el formulario se pondrá rojo solo)
      print("❌ Intento de login con campos vacíos");
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
                  // 3. Envolvemos los campos en un widget Form
                  child: Form(
                    key: _formKey, // Asignamos la llave maestra
                    child: Column(
                      children: [
                        // Input: Celular (Ahora es TextFormField)
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Número de Celular',
                            prefixIcon: Icon(Icons.phone_android),
                            border: OutlineInputBorder(),
                          ),
                          // AQUI ESTA LA REGLA DE VALIDACION:
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu celular';
                            }
                            return null; // Null significa "todo está bien"
                          },
                        ),
                        const SizedBox(height: 20),

                        // Input: Código de Apto
                        TextFormField(
                          controller: _codeController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Código de Apartamento',
                            prefixIcon: Icon(Icons.vpn_key),
                            border: OutlineInputBorder(),
                            helperText: 'Ej: T1-502-XYZ',
                          ),
                          // AQUI ESTA LA REGLA DE VALIDACION:
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El código es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

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