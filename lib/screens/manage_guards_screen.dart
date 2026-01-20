import 'dart:math'; // Para generar PIN aleatorio
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';
import '../services/audit_logger.dart'; 

class ManageGuardsScreen extends StatefulWidget {
  const ManageGuardsScreen({super.key});

  @override
  State<ManageGuardsScreen> createState() => _ManageGuardsScreenState();
}

class _ManageGuardsScreenState extends State<ManageGuardsScreen> {
  bool _isLoading = false;
  List<User> _guards = [];

  // Controladores para nuevo portero
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGuards();
  }

  // --- 1. LISTAR PORTEROS ---
  Future<void> _fetchGuards() async {
    setState(() => _isLoading = true);
    try {
      final request = ModelQueries.list(
        User.classType,
        where: User.ROLE.eq(Role.GUARD), 
      );
      
      final response = await Amplify.API.query(request: request).response;
      
      if (response.data != null) {
        var allGuards = response.data!.items.whereType<User>().toList();
        
        // 🔥 FILTRO (Mantenemos tu lógica de ocultar Tablets)
        allGuards = allGuards.where((u) {
            return u.isDevice != true; 
        }).toList();
        
        // Ordenamos
        allGuards.sort((a, b) {
          if (a.isActive == b.isActive) {
             return (a.name ?? "").compareTo(b.name ?? "");
          }
          return (a.isActive == true) ? -1 : 1;
        });

        setState(() => _guards = allGuards);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. CREAR PORTERO ---
  Future<void> _createGuard() async {
    if (_nameController.text.isEmpty || _pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre y PIN de 4 dígitos obligatorios.")));
      return;
    }

    try {
      Navigator.pop(context); // Cerrar diálogo
      setState(() => _isLoading = true);

      String generatedUsername = "guard_${DateTime.now().millisecondsSinceEpoch}";

      final newGuard = User(
        username: generatedUsername,
        name: _nameController.text.trim(),
        pinCode: _pinController.text.trim(),
        role: Role.GUARD,
        isFirstLogin: false,
        isActive: true,
        email: "guard@sistema.com", 
        isDevice: false, // Aseguramos que sea humano
      );

      final request = ModelMutations.create(
        newGuard, 
        authorizationMode: APIAuthorizationType.apiKey
      );
      
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) throw Exception(response.errors.first.message);

      try {
        AuditLogger.log(
          action: "CREAR_PORTERO",
          target: _nameController.text,
          details: "Nuevo personal registrado",
        );
      } catch (_) {} 

      _nameController.clear();
      _pinController.clear();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Portero creado correctamente"), backgroundColor: Colors.green));
      _fetchGuards(); 

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creando: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. REGENERAR PIN ---
  Future<void> _regeneratePin(User guard) async {
    final newPin = (Random().nextInt(9000) + 1000).toString(); 

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cambiar PIN?"),
        content: Text("Se generará un nuevo código para ${guard.name}. El anterior dejará de funcionar."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Generar")),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      const String doc = '''mutation UpdateGuardPin(\$id: ID!, \$pinCode: String!) {
          updateUser(input: {id: \$id, pinCode: \$pinCode}) { id pinCode }
      }''';
      final req = GraphQLRequest<String>(document: doc, variables: {'id': guard.id, 'pinCode': newPin});
      final res = await Amplify.API.mutate(request: req).response;
      
      if (res.hasErrors) throw Exception(res.errors.first.message);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.indigo,
            title: const Text("¡Nuevo PIN!", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Dicta este código:", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text(newPin, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 5)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: newPin));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiado")));
                  }, 
                  icon: const Icon(Icons.copy, size: 15), 
                  label: const Text("Copiar")
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar", style: TextStyle(color: Colors.white)))
            ],
          ),
        );
      }
      
      try {
        AuditLogger.log(action: "CAMBIO_PIN", target: guard.name ?? "Portero", details: "PIN Regenerado");
      } catch (_) {}

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 4. ACTIVAR / DESACTIVAR ---
  Future<void> _toggleGuardStatus(User guard) async {
    final newStatus = !(guard.isActive ?? true);
    
    setState(() {
      final index = _guards.indexWhere((u) => u.id == guard.id);
      if(index != -1) _guards[index] = guard.copyWith(isActive: newStatus);
    });

    try {
      const String doc = '''mutation UpdateStatus(\$id: ID!, \$isActive: Boolean!) {
          updateUser(input: {id: \$id, isActive: \$isActive}) { id isActive }
      }''';
      final req = GraphQLRequest<String>(document: doc, variables: {'id': guard.id, 'isActive': newStatus});
      final res = await Amplify.API.mutate(request: req).response;

      if (res.hasErrors) throw Exception(res.errors.first.message);

      try {
        AuditLogger.log(
          action: newStatus ? "ACTIVAR_PORTERO" : "BLOQUEAR_PORTERO",
          target: guard.name ?? "Portero",
          details: "ID: ${guard.id}",
        );
      } catch (_) {}

    } catch (e) {
      setState(() {
        final index = _guards.indexWhere((u) => u.id == guard.id);
        if(index != -1) _guards[index] = guard.copyWith(isActive: !newStatus);
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar estado")));
    }
  }

  void _showAddGuardDialog() {
    _nameController.clear();
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nuevo Portero"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Este perfil servirá para validar el ingreso con PIN en la tablet."),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre (ej: Don José)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pinController,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Asignar PIN Inicial", border: OutlineInputBorder(), hintText: "1234"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: _createGuard,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text("Guardar"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // 👇👇 AQUÍ ESTÁ LA SOLUCIÓN: Agregamos el AppBar 👇👇
      appBar: AppBar(
        title: const Text("Gestión de Porteros", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        // Esto agrega la flecha automáticamente si hay historial. 
        // Si no hay flecha, puedes forzarla descomentando esto:
        /*
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), 
        ),
        */
      ),
      // 👆👆 FIN DE LA SOLUCIÓN 👆👆
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuardDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Portero"),
      ),
      body: _isLoading && _guards.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _guards.isEmpty 
          ? const Center(child: Text("No hay porteros registrados.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _guards.length,
              itemBuilder: (context, index) {
                final guard = _guards[index];
                final isActive = guard.isActive ?? true;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.blue.shade50 : Colors.grey.shade200,
                      child: Icon(Icons.local_police, color: isActive ? Colors.blue : Colors.grey),
                    ),
                    title: Text(guard.name ?? "Sin Nombre", style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
                    subtitle: Text(isActive ? "🟢 Activo" : "🔴 Inactivo (Bloqueado)"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.vpn_key, color: Colors.orange),
                          tooltip: "Cambiar PIN",
                          onPressed: isActive ? () => _regeneratePin(guard) : null,
                        ),
                        Switch(
                          value: isActive,
                          activeColor: Colors.green,
                          onChanged: (val) => _toggleGuardStatus(guard),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}