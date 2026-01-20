import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';

class DataSeeder {
  
  // Torres 1, 2 y 4 (Saltando la 3 como pediste)
  static const List<String> torres = ['Torre 1', 'Torre 2', 'Torre 4'];
  
  static const List<String> aptos = [
    '101', '102', '103', '104', '105', 
    '201', '202', '203', '204', '205'
  ];

  // --- 1. SEMBRAR APARTAMENTOS (CORREGIDO) ---
  static Future<void> sembrarApartamentos() async {
    int creados = 0;
    int existentes = 0;
    int fallidos = 0;
    print("🌱 Iniciando siembra de Apartamentos (Torres 1, 2 y 4)...");

    try {
      // Traemos lo que ya existe para no repetir
      final existingApts = await _getAllApartments();
      print("📊 Base de datos actual: ${existingApts.length} apartamentos encontrados.");

      for (String torre in torres) {
        for (String unidad in aptos) {
          
          String numeroTorre = torre.split(' ').last; 
          String accessCode = "$numeroTorre$unidad"; 

          // Verificamos si ya existe
          final existe = existingApts.any((a) => a.accessCode == accessCode);

          if (existe) {
            existentes++;
            continue; 
          }

          try {
            final nuevoApto = Apartment(
              tower: torre,
              unitNumber: unidad,
              accessCode: accessCode, 
            );

            final request = ModelMutations.create(nuevoApto, authorizationMode: APIAuthorizationType.apiKey);
            final response = await Amplify.API.mutate(request: request).response;

            if (response.hasErrors) {
              // 🔥 AQUÍ ESTABA EL ERROR: Ahora sí imprimimos qué pasó
              print("❌ Rechazado $torre $unidad: ${response.errors.first.message}");
              fallidos++;
            } else {
              print("✅ Creado Apto: $torre $unidad");
              creados++;
            }
          } catch (e) {
            print("⚠️ Excepción local creando apto: $e");
            fallidos++;
          }
        }
      }
    } catch (e) {
      print("💀 Error crítico trayendo aptos iniciales: $e");
    }

    print("--------------------------------");
    print("🏁 FIN APTOS");
    print("✅ Creados: $creados");
    print("⏭️ Ya existían: $existentes");
    print("❌ Fallidos: $fallidos");
    print("--------------------------------");
  }

  // --- 2. SEMBRAR USUARIOS ---
  static Future<void> sembrarUsuarios() async {
    print("👤 Iniciando siembra de Usuarios...");
    int creados = 0;
    int existentes = 0;

    final listaAptos = await _getAllApartments();
    
    // Filtramos para NO tocar la Torre 3
    final aptosFiltrados = listaAptos.where((a) => a.tower != 'Torre 3').toList();
    
    if (aptosFiltrados.isEmpty) {
      print("⚠️ No hay apartamentos de Torre 1, 2 o 4 en la BD.");
      return;
    }

    final existingUsers = await _getAllUsers();

    for (var apto in aptosFiltrados) {
      final cleanTower = apto.tower.replaceAll(" ", ""); 
      final username = "${cleanTower}_${apto.unitNumber}".toLowerCase(); 

      if (existingUsers.any((u) => u.username == username)) {
        existentes++;
        continue;
      }

      try {
        final nuevoUsuario = User(
          username: username,
          password: "123456",
          name: "Vecino ${apto.unitNumber} ${apto.tower}",
          role: Role.RESIDENT,
          isFirstLogin: false,
          apartment: apto, 
        );

        final reqUser = ModelMutations.create(nuevoUsuario, authorizationMode: APIAuthorizationType.apiKey);
        final resUser = await Amplify.API.mutate(request: reqUser).response;

        if (resUser.hasErrors) {
           print("❌ Error Usuario $username: ${resUser.errors.first.message}");
        } else {
           print("✅ Usuario creado: $username");
           creados++;
        }
      } catch (e) {
        print("Error usuario: $e");
      }
    }

    print("🏁 FIN USUARIOS: Creados: $creados | Ya existían: $existentes");
  }

  // Helpers
  static Future<List<Apartment>> _getAllApartments() async {
    try {
      final request = ModelQueries.list(Apartment.classType, limit: 1000, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.query(request: request).response;
      return response.data?.items.whereType<Apartment>().toList() ?? [];
    } catch (e) { return []; }
  }

  static Future<List<User>> _getAllUsers() async {
    try {
      final request = ModelQueries.list(User.classType, limit: 1000, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.query(request: request).response;
      return response.data?.items.whereType<User>().toList() ?? [];
    } catch (e) { return []; }
  }
}