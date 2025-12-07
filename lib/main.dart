import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'amplifyconfiguration.dart'; // El archivo que genera Amplify CLI
import 'models/ModelProvider.dart'; // Tus modelos

// Importamos las pantallas
import 'screens/login_screen.dart';
import 'screens/guard_home_screen.dart'; // 👈 La nueva pantalla principal

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amplifyConfigured = false;
  bool _isUserLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  // 1. Configuración de Amplify y Verificación de Sesión
  Future<void> _configureAmplify() async {
    try {
      // Evitar configurar dos veces (Hot Reload)
      if (!Amplify.isConfigured) {
        final api = AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider.instance));
        final auth = AmplifyAuthCognito();
        final storage = AmplifyStorageS3();
        
        await Amplify.addPlugins([api, auth, storage]);
        await Amplify.configure(amplifyconfig);
      }
      
      // 2. Comprobar si ya hay un usuario logueado
      try {
        final result = await Amplify.Auth.fetchAuthSession();
        if (result.isSignedIn) {
          setState(() {
            _isUserLoggedIn = true;
          });
        }
      } catch (e) {
        print("No hay sesión activa: $e");
      }

      setState(() {
        _amplifyConfigured = true;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error configurando Amplify: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portería App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // Lógica de navegación inicial
      home: _isLoading 
        ? const Scaffold(body: Center(child: CircularProgressIndicator())) // Cargando...
        : _isUserLoggedIn 
            ? const GuardHomeScreen() // 👈 Si ya entró, va al menú nuevo
            : const LoginScreen(),    // 👈 Si no, al Login
    );
  }
}