import 'package:flutter/material.dart';
// 1. Importamos las librerías de AWS
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';

// 2. Importamos la configuración y los modelos generados
import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';
import 'screens/login_screen.dart'; 

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
  String _statusMessage = 'Iniciando conexión con AWS...';

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      // A. Agregamos los plugins (Auth y API)
      final auth = AmplifyAuthCognito();
      final api = AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider.instance));
      await Amplify.addPlugins([auth, api]);

      // B. Leemos la configuración de AWS
      await Amplify.configure(amplifyconfig);

      setState(() {
        _amplifyConfigured = true;
        _statusMessage = '✅ ¡Conectado a AWS exitosamente!';
      });
      safePrint('Amplify configurado correctamente');
    } on Exception catch (e) {
      setState(() {
        _statusMessage = '❌ Error de conexión: $e';
      });
      safePrint('Error configurando Amplify: $e');
    }
  }

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: _amplifyConfigured
          ? const LoginScreen() 
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}