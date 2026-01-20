import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';

class GuardPinDialog extends StatefulWidget {
  final String action; 
  const GuardPinDialog({super.key, required this.action});

  @override
  State<GuardPinDialog> createState() => _GuardPinDialogState();
}

class _GuardPinDialogState extends State<GuardPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isValidating = false;
  String? _errorText;

  Future<void> _validatePin() async {
    // Validación básica de longitud
    if (_pinController.text.length < 4) return;

    setState(() {
      _isValidating = true;
      _errorText = null;
    });

    try {
      final pin = _pinController.text.trim();
      print("🔐 Verificando PIN: $pin"); 
      
      // 1. Preparamos la consulta
      // Buscamos usuarios que coincidan con el PIN
      // Nota: Quitamos el filtro de ROL aquí para validarlo manualmente y dar un mensaje más claro
      final request = ModelQueries.list(
        User.classType,
        where: User.PINCODE.eq(pin),
      );
      
      // 2. Ejecutamos con API Key (Pública)
      final response = await Amplify.API.query(
        request: GraphQLRequest<PaginatedResult<User>>(
          document: request.document,
          variables: request.variables,
          modelType: request.modelType,
          decodePath: request.decodePath,
          authorizationMode: APIAuthorizationType.apiKey 
        )
      ).response;

      // 3. 🛑 INTERCEPTOR DE PANTALLA ROJA
      // Si DynamoDB se queja de "null value", es porque el usuario es viejo y le falta isActive
      if (response.hasErrors) {
        final firstError = response.errors.first.message;
        if (firstError.contains("non-nullable") || firstError.contains("isActive")) {
           throw Exception("Ficha desactualizada (Falta isActive en BD)");
        }
        throw Exception(firstError);
      }

      final guards = response.data?.items;

      if (guards != null && guards.isNotEmpty) {
        // Obtenemos el primero que coincida
        final guard = guards.first;
        
        if (guard == null) throw Exception("Error de lectura");

        // VALIDACIÓN A: ¿Es Portero?
        if (guard.role != Role.GUARD) {
          setState(() => _errorText = "Este PIN no es de portero");
          return;
        }

        // VALIDACIÓN B: ¿Está Activo?
        // Usamos (guard.isActive ?? false) para que si es nulo, lo tome como inactivo sin explotar
        if ((guard.isActive ?? false) == false) {
           setState(() => _errorText = "Usuario Inactivo o Bloqueado");
           return;
        }

        // 🎉 ÉXITO
        print("✅ Portero identificado: ${guard.name}");
        if (mounted) {
           Navigator.pop(context, guard.name ?? "Portero"); 
        }

      } else {
        // ❌ NO ENCONTRADO
        print("⚠️ PIN no encontrado en base de datos");
        setState(() => _errorText = "PIN Incorrecto");
      }

    } catch (e) {
      print("🔥 Error gestionado: $e");
      // Mensaje amigable según el error
      String msg = "Error verificando PIN";
      if (e.toString().contains("Ficha desactualizada")) {
        msg = "Error: Usuario antiguo (Falta actualizar datos)";
      }
      setState(() => _errorText = msg);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 40, color: Colors.indigo),
          const SizedBox(height: 10),
          Text("Portero: ${widget.action}", style: const TextStyle(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Ingresa tu PIN personal:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Para registrar quién realiza esta acción.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            // Aumenté un poco el letterSpacing para que parezca un PIN
            style: const TextStyle(fontSize: 30, letterSpacing: 15, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              errorText: _errorText,
              errorMaxLines: 2, // Para que quepan los mensajes largos
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              counterText: "",
              hintText: "••••",
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 15)
            ),
            onChanged: (val) {
              if (val.length == 4) _validatePin(); 
            },
          ),
          
          // Indicador de carga pequeño debajo
          if (_isValidating)
            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: SizedBox(
                width: 20, height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2)
              ),
            )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null), 
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}