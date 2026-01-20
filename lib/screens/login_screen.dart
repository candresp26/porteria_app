import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ModelProvider.dart'; 
import 'guard_home_screen.dart';
import 'resident_home_screen.dart'; 
import 'sign_up_screen.dart';
// 👇 1. IMPORTAMOS LA NUEVA PANTALLA DE ADMIN
import 'admin_dashboard_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLoginBiometrics();
  }

  // INTENTO DE LOGIN AUTOMÁTICO SI LA BIOMETRÍA ESTABA ACTIVADA
  Future<void> _checkAutoLoginBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    bool useBiometrics = prefs.getBool('useBiometrics') ?? false;
    // Si el usuario tenía activada la biometría, lanzamos el prompt automáticamente
    if (useBiometrics) {
      _authenticate();
    }
  }

  // 👇 2. AQUÍ ESTÁ EL POLICÍA DE TRÁFICO (ACTUALIZADO)
  void _navigateBasedOnRole(String role) {
    if (role == 'ADMIN') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
    } else if (role == 'GUARD') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GuardHomeScreen()));
    } else {
      // Por defecto, cualquier otro rol va a Residentes
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ResidentHomeScreen()));
    }
  }

// 🔥 LÓGICA DE LOGIN MANUAL (Con Fix de sesión fantasma + Guardado de Credenciales)
  Future<void> _loginManual() async {
    final usernameInput = _userController.text.trim();
    final passwordInput = _passController.text.trim();

    if (usernameInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ingresa usuario y contraseña")));
      return;
    }

    if (!_isLoading) setState(() => _isLoading = true);

    try {
      // Intentamos iniciar sesión
      final result = await Amplify.Auth.signIn(
        username: usernameInput,
        password: passwordInput,
      );

      if (result.isSignedIn) {
        // Guardamos pass para biometría futura
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cachedPass', passwordInput); 
        
        await _fetchUserDataAndNavigate(usernameInput);
      }
    } on AuthException catch (e) {
      
      // FIX DE SESIÓN FANTASMA MEJORADO
      if (e.message.contains('already signed in') || 
          e.message.contains('current user')) {
        
        print("⚠️ Sesión fantasma detectada. Limpiando y reintentando...");
        try {
          await Amplify.Auth.signOut(); 
        } catch (_) {}
        
        // Esperamos un poco para asegurar que Amplify limpió la memoria
        await Future.delayed(const Duration(milliseconds: 500));
        await _loginManual(); // Reintento
        return; 
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("AWS Error: ${e.message}"), 
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error General: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserDataAndNavigate(String username) async {
    try {
      // Buscamos al usuario en DynamoDB
      final baseRequest = ModelQueries.list(
        User.classType,
        where: User.USERNAME.eq(username),
      );

      // Usamos API Key (Public) para leer al usuario y saber quién es
      final request = GraphQLRequest<PaginatedResult<User>>(
        document: baseRequest.document,
        variables: baseRequest.variables,
        modelType: baseRequest.modelType,
        decodePath: baseRequest.decodePath,
        authorizationMode: APIAuthorizationType.apiKey,
      );
      
      final response = await Amplify.API.query(request: request).response;
      final data = response.data;

      if (data == null || data.items.isEmpty) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario no encontrado en base de datos")));
        return;
      }

      final foundUser = data.items.first;

      if (foundUser != null) {
        final prefs = await SharedPreferences.getInstance();
        
        // 👇 3. CLASIFICACIÓN EXACTA DE ROLES
        String roleString = 'RESIDENT'; // Valor por defecto
        
        if (foundUser.role == Role.ADMIN) {
          roleString = 'ADMIN';
        } else if (foundUser.role == Role.GUARD) {
          roleString = 'GUARD';
        } 
        // Si es RESIDENT, se queda con el valor por defecto

        // Guardamos datos persistentes
        await prefs.setString('userId', foundUser.id);
        await prefs.setString('username', foundUser.name ?? "Usuario");
        await prefs.setString('email', username);
        await prefs.setString('role', roleString);
        await prefs.setString('tower', foundUser.tower ?? ''); 
        await prefs.setString('unit', foundUser.unit ?? '');
        // En login_screen.dart
        await prefs.setString('name', foundUser.name ?? "Admin"); // <--- ESTA ES LA CLAVE
        
        // ACTIVAMOS LA BANDERA DE BIOMETRÍA
        await prefs.setBool('useBiometrics', true);

        if(mounted) _navigateBasedOnRole(roleString);
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // =========================================================
  // 🖐️ LÓGICA BIOMÉTRICA MEJORADA
  // =========================================================
  Future<void> _authenticate() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? storedUser = prefs.getString('email'); 
    final String? storedPass = prefs.getString('cachedPass');

    if (storedUser == null || storedPass == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa con contraseña la primera vez para activar la huella.")));
      return;
    }

    bool authenticated = false;
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        authenticated = await auth.authenticate(
          localizedReason: 'Toca el sensor para ingresar',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Huella no disponible en este dispositivo")));
        return;
      }
    } on PlatformException catch (e) {
      print("Error biométrico: $e");
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _userController.text = storedUser;
        _passController.text = storedPass;
      });
      
      _loginManual(); 
    }
  }

  // =========================================================
  // 🔐 LÓGICA DE OLVIDÉ MI CONTRASEÑA (INTACTA)
  // =========================================================
  
  void _showForgotPasswordDialog() {
    final userResetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Recuperar Contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ingresa tu usuario para enviarte un código al correo registrado."),
            const SizedBox(height: 15),
            TextField(
              controller: userResetController,
              decoration: const InputDecoration(labelText: "Usuario", hintText: "Ej: luisa.perez", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (userResetController.text.isEmpty) return;
              try {
                await Amplify.Auth.resetPassword(username: userResetController.text.trim());
                if (mounted) {
                  Navigator.pop(ctx); 
                  _showConfirmResetDialog(userResetController.text.trim()); 
                }
              } on AuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
              }
            },
            child: const Text("Enviar Código"),
          )
        ],
      )
    );
  }

  void _showConfirmResetDialog(String username) {
    final codeController = TextEditingController();
    final newPassController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambiar Contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Revisa tu correo e ingresa el código."),
            const SizedBox(height: 15),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Código de verificación", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva Contraseña", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty || newPassController.text.isEmpty) return;
              try {
                await Amplify.Auth.confirmResetPassword(
                  username: username,
                  newPassword: newPassController.text.trim(),
                  confirmationCode: codeController.text.trim()
                );
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("✅ ¡Contraseña cambiada! Ahora inicia sesión."), 
                    backgroundColor: Colors.green
                  ));
                }
              } on AuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
              }
            },
            child: const Text("Cambiar"),
          )
        ],
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 🔥 TU UI ORIGINAL EXACTA 🔥
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // FONDO
          Positioned(top: -50, left: -50, child: _buildBubble(200, const Color(0xFF2DD4BF).withOpacity(0.3))),
          Positioned(top: 100, right: -30, child: _buildBubble(120, const Color(0xFF0F172A).withOpacity(0.1))),
          Positioned(bottom: -80, right: -20, child: _buildBubble(250, const Color(0xFF2DD4BF).withOpacity(0.2))),
          Positioned(bottom: 150, left: -40, child: _buildBubble(100, const Color(0xFF0F172A).withOpacity(0.05))),

          // CONTENIDO
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: const Icon(Icons.security, size: 60, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 20),
                  const Text("URBIAN", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 2.0)),
                  const SizedBox(height: 10),
                  Text("Acceso Seguro", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 50),

                  // INPUTS
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      labelText: "Usuario",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _passController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // LOGIN
                  _isLoading 
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _loginManual, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A), 
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("INGRESAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                   const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                    },
                    child: const Text("¿Eres nuevo? Regístrate aquí"),
                  ),   
                  
                  const SizedBox(height: 40),
                  
                  // BIOMETRÍA
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("O ingresa con", style: TextStyle(color: Colors.grey[500]))),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  InkWell(
                    onTap: _authenticate,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]
                      ),
                      child: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF2DD4BF)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Biometría", style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}