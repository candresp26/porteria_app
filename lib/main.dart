import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';

// ✅ IMPORTS CLAROS (Asegúrate de que las rutas coincidan con tus carpetas)
import 'screens/login_screen.dart';
import 'screens/guard_home_screen.dart';
import 'screens/dashboard_screen.dart'; 

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
  bool _isLoading = true;
  
  // 🔴 CORRECCIÓN 1: Quitamos 'const' y dejamos un valor nulo inicial o instanciamos simple
  Widget _startScreen = LoginScreen(); 

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      if (!Amplify.isConfigured) {
        final api = AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider.instance));
        final auth = AmplifyAuthCognito();
        final storage = AmplifyStorageS3();
        
        await Amplify.addPlugins([api, auth, storage]);
        await Amplify.configure(amplifyconfig);
      }
      
      await _checkSessionAndRole();

    } catch (e) {
      print('Error configurando Amplify: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkSessionAndRole() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      
      if (session.isSignedIn) {
        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString('role');

        print("🔍 Main: Sesión activa. Rol: $role");

        if (role == 'GUARD') {
           setState(() {
             // 🔴 CORRECCIÓN 2: Sin 'const'
             _startScreen = GuardHomeScreen();
           });
        } else if (role == 'RESIDENT' || role == 'ADMIN') { 
           setState(() {
             // 🔴 CORRECCIÓN 3: Sin 'const'
             _startScreen = DashboardScreen(); 
           });
        } else {
          setState(() {
            _startScreen = LoginScreen();
          });
        }
      } else {
        setState(() {
          _startScreen = LoginScreen();
        });
      }
    } catch (e) {
      print("Error sesión: $e");
      setState(() {
         _startScreen = LoginScreen();
      });
    } finally {
      setState(() {
        _amplifyConfigured = true;
        _isLoading = false;
      });
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
      home: _isLoading 
        ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
        : _startScreen, 
    );
  }
}