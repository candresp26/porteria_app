import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuditLogger {
  
  // Función estática para llamar desde cualquier lado
  static Future<void> log({
    required String action, // Ej: "BLOQUEAR_VECINO"
    required String target, // Ej: "Juan Perez"
    String details = "",    // Ej: "Torre 1 - 101"
  }) async {
    try {
      // 1. Obtener quién está logueado (El Admin responsable)
      final prefs = await SharedPreferences.getInstance();
      final String actor = prefs.getString('name') ?? "Admin Desconocido";

      // 2. Crear el registro
      final newLog = AuditLog(
        action: action,
        actorName: actor,
        targetName: target,
        details: details,
        // createdAt lo gestiona DynamoDB, pero Flutter lo leerá después
      );

      // 3. Guardar en la nube
      final request = ModelMutations.create(newLog);
      await Amplify.API.mutate(request: request).response;
      
      print("📝 Auditoría: $action -> $target");

    } catch (e) {
      print("⚠️ Error guardando auditoría: $e");
    }
  }
}