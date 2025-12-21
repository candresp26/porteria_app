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
      print("🔐 Verificando PIN: $pin"); // Log para depurar
      
      // 1. Preparamos la consulta
      final request = ModelQueries.list(
        User.classType,
        where: User.PINCODE.eq(pin).and(User.ROLE.eq(Role.GUARD)),
      );
      
      // 2. 🔥 EL FIX: Forzamos authorizationMode: APIAuthorizationType.apiKey
      final response = await Amplify.API.query(
        request: GraphQLRequest<PaginatedResult<User>>(
          document: request.document,
          variables: request.variables,
          modelType: request.modelType,
          decodePath: request.decodePath,
          authorizationMode: APIAuthorizationType.apiKey // 👈 ESTO FALTABA
        )
      ).response;

      // 3. Revisamos errores de GraphQL
      if (response.hasErrors) {
        print("❌ Error GraphQL: ${response.errors.first.message}");
        throw Exception(response.errors.first.message);
      }

      final guards = response.data?.items;

      if (guards != null && guards.isNotEmpty) {
        // 🎉 ÉXITO: Encontramos al portero
        final guard = guards.first;
        print("✅ Portero identificado: ${guard?.name}");
        
        if (mounted) {
           Navigator.pop(context, guard?.name ?? "Portero"); 
        }
      } else {
        // ❌ NO ENCONTRADO
        print("⚠️ PIN no encontrado en base de datos");
        setState(() => _errorText = "PIN no válido");
      }

    } catch (e) {
      print("🔥 Error técnico verificando PIN: $e");
      setState(() => _errorText = "Error verificando PIN");
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Portero: ${widget.action}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Ingresa tu PIN personal:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Para registrar quién realiza esta acción.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 15),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              errorText: _errorText,
              border: const OutlineInputBorder(),
              counterText: "",
              hintText: "••••",
              filled: true,
              fillColor: Colors.grey[100]
            ),
            onChanged: (val) {
              if (val.length == 4) _validatePin(); 
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null), 
          child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}