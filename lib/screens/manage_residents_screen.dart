import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';
import '../services/audit_logger.dart'; 

class ManageResidentsScreen extends StatefulWidget {
  const ManageResidentsScreen({super.key});

  @override
  State<ManageResidentsScreen> createState() => _ManageResidentsScreenState();
}

class _ManageResidentsScreenState extends State<ManageResidentsScreen> {
  bool _isLoading = false;
  
  // Datos
  List<User> _allResidents = []; 
  List<User> _searchResults = []; 
  Map<String, Apartment> _apartmentMap = {}; 
  
  // Estructura visual
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, List<User>>> _groupedResidents = {};
  List<String> _sortedTowers = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // --- 1. CARGA DE DATOS ---
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Amplify.API.query(request: ModelQueries.list(User.classType, where: User.ROLE.eq(Role.RESIDENT))).response,
        Amplify.API.query(request: ModelQueries.list(Apartment.classType)).response,
      ]);

      final userResponse = results[0] as GraphQLResponse<PaginatedResult<User>>;
      final aptResponse = results[1] as GraphQLResponse<PaginatedResult<Apartment>>;

      if (userResponse.data != null) {
        _allResidents = userResponse.data!.items.whereType<User>().toList();
        _organizeData(_allResidents);
      }

      if (aptResponse.data != null) {
        final apts = aptResponse.data!.items.whereType<Apartment>().toList();
        _apartmentMap.clear();
        for (var apt in apts) {
          final key = "${apt.tower.trim()}-${apt.unitNumber.trim()}";
          _apartmentMap[key] = apt;
        }
      }

    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _organizeData(List<User> users) {
    final Map<String, Map<String, List<User>>> structure = {};

    for (var user in users) {
      final tower = user.tower ?? "Sin Torre";
      final apt = user.unit ?? "Sin Apto";

      if (!structure.containsKey(tower)) structure[tower] = {};
      if (!structure[tower]!.containsKey(apt)) structure[tower]![apt] = [];
      structure[tower]![apt]!.add(user);
    }

    final sortedKeys = structure.keys.toList()..sort();
    
    setState(() {
      _groupedResidents = structure;
      _sortedTowers = sortedKeys;
    });
  }

  void _filterResidents(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _isSearching = true;
      _searchResults = _allResidents.where((user) {
        return (user.name ?? "").toLowerCase().contains(lowerQuery) || 
               (user.tower ?? "").toLowerCase().contains(lowerQuery) || 
               (user.unit ?? "").toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  // --- 2. GESTIÓN DE USUARIOS (Activar/Bloquear) ---
  Future<void> _toggleResidentStatus(User resident) async {
    final bool currentStatus = resident.isActive ?? true;
    final bool newStatus = !currentStatus;

    setState(() {
      final index = _allResidents.indexWhere((u) => u.id == resident.id);
      if (index != -1) {
        _allResidents[index] = resident.copyWith(isActive: newStatus);
        if (_isSearching) {
           final searchIndex = _searchResults.indexWhere((u) => u.id == resident.id);
           if (searchIndex != -1) _searchResults[searchIndex] = resident.copyWith(isActive: newStatus);
        }
        _organizeData(_allResidents);
      }
    });

    try {
       // Usamos userPools para asegurar permisos de escritura (Admin)
       final request = ModelMutations.update(
         resident.copyWith(isActive: newStatus),
         authorizationMode: APIAuthorizationType.userPools 
       );
      
      final response = await Amplify.API.mutate(request: request).response;
      
      if (response.hasErrors) throw Exception(response.errors.first.message);

      try {
        AuditLogger.log(
          action: newStatus ? "ACTIVAR_VECINO" : "BLOQUEAR_VECINO",
          target: resident.name ?? "Vecino", 
          details: "${resident.tower ?? '?'} - ${resident.unit ?? '?'}",
        );
      } catch (_) {}

    } catch (e) {
      setState(() {
         final index = _allResidents.indexWhere((u) => u.id == resident.id);
         if (index != -1) {
           _allResidents[index] = resident.copyWith(isActive: currentStatus);
           _organizeData(_allResidents);
         }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 3. GESTIÓN DE CÓDIGOS DE APARTAMENTO ---
  String _formatExpiry(TemporalDateTime? date) {
    if (date == null) return "Inactivo";
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      if (d.isBefore(DateTime.now())) return "VENCIDO";
      return "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    } catch (e) { return "--"; }
  }

  Future<void> _manageCode(String tower, String unit, {bool revoke = false}) async {
    final key = "${tower.trim()}-${unit.trim()}";
    final apt = _apartmentMap[key];

    if (apt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: El apartamento no existe en base de datos")));
      return;
    }

    if (revoke) {
      bool confirm = await showDialog(context: context, builder: (c) => AlertDialog(
        title: const Text("¿Eliminar Código?"),
        content: const Text("Se borrará el acceso actual."),
        actions: [TextButton(onPressed:()=>Navigator.pop(c,false), child: const Text("Cancelar")), TextButton(onPressed:()=>Navigator.pop(c,true), child: const Text("Eliminar"))]
      )) ?? false;
      if (!confirm) return;
    }

    setState(() => _isLoading = true);
    try {
      String? newCode;
      TemporalDateTime? expires;
      
      if (!revoke) {
        newCode = (Random().nextInt(900000) + 100000).toString(); 
        expires = TemporalDateTime(DateTime.now().add(const Duration(days: 7)));
      }

      final updatedApt = apt.copyWith(accessCode: newCode, codeExpiresAt: expires);
      
      // Permisos de Admin (userPools)
      final req = ModelMutations.update(
        updatedApt, 
        authorizationMode: APIAuthorizationType.userPools
      );
      final res = await Amplify.API.mutate(request: req).response;

      if (res.hasErrors) throw Exception(res.errors.first.message);

      _apartmentMap[key] = updatedApt;
      
      if (mounted) {
        if (!revoke && newCode != null) {
           showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.indigo,
              title: const Text("¡Código Generado!", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(newCode!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 5)),
                  Text("Vence: ${_formatExpiry(expires)}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: newCode!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiado")));
                  }, 
                  icon: const Icon(Icons.copy, color: Colors.white), 
                  label: const Text("Copiar", style: TextStyle(color: Colors.white))
                ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar", style: TextStyle(color: Colors.white)))
              ],
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código eliminado"), backgroundColor: Colors.red));
        }
      }
      
      try { AuditLogger.log(action: revoke ? "ELIMINAR_CODIGO" : "GENERAR_CODIGO", target: "$tower $unit"); } catch (_) {}

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 4. MUDANZA ---
  Future<void> _processMoveOut(String tower, String unit, List<User> residents) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🚚 Confirmar Mudanza"),
        content: Text("Se desactivarán los ${residents.length} residentes de $tower - $unit y se borrará el código de acceso."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Confirmar"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    setState(() => _isLoading = true);

    try {
      for (var resident in residents) {
        if (resident.isActive == true) {
           final disabledUser = resident.copyWith(isActive: false);
           await Amplify.API.mutate(
             request: ModelMutations.update(disabledUser, authorizationMode: APIAuthorizationType.userPools)
           ).response;
        }
      }

      final key = "${tower.trim()}-${unit.trim()}";
      final apt = _apartmentMap[key];
      if (apt != null) {
        final cleanApt = apt.copyWith(accessCode: null, codeExpiresAt: null);
        await Amplify.API.mutate(
          request: ModelMutations.update(cleanApt, authorizationMode: APIAuthorizationType.userPools)
        ).response;
        _apartmentMap[key] = cleanApt;
      }

      _fetchAllData(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mudanza procesada con éxito"), backgroundColor: Colors.orange));
      
      try { AuditLogger.log(action: "MUDANZA_SALIDA", target: "$tower $unit"); } catch (_) {}

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // 👇👇 AQUÍ AGREGUÉ LA BARRA SUPERIOR PARA PODER VOLVER 👇👇
      appBar: AppBar(
        title: const Text("Gestión Residentes", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white, // Esto hace que la flecha sea blanca
      ),
      // 👆👆 FIN DEL CAMBIO 👆👆
      
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
            child: TextField(
              controller: _searchController,
              onChanged: _filterResidents,
              decoration: InputDecoration(
                hintText: "Buscar vecino, torre o apto...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isSearching
                  ? _buildSearchResults()
                  : _buildHierarchicalView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchicalView() {
    if (_sortedTowers.isEmpty) {
      return const Center(child: Text("No hay datos.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _sortedTowers.length,
      itemBuilder: (context, index) {
        final towerName = _sortedTowers[index];
        final apartmentsMap = _groupedResidents[towerName]!;
        
        final sortedApts = apartmentsMap.keys.toList()..sort((a, b) {
          final intA = int.tryParse(a) ?? 0;
          final intB = int.tryParse(b) ?? 0;
          if (intA > 0 && intB > 0) return intA.compareTo(intB);
          return a.compareTo(b);
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.apartment, color: Colors.indigo),
              ),
              title: Text(
                towerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
              ),
              childrenPadding: const EdgeInsets.all(15),
              children: sortedApts.map((aptNum) {
                final residentsInApt = apartmentsMap[aptNum]!;
                return _buildApartmentCard(towerName, aptNum, residentsInApt);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApartmentCard(String tower, String aptNum, List<User> residents) {
    final key = "${tower.trim()}-${aptNum.trim()}";
    final aptData = _apartmentMap[key];
    final hasCode = aptData?.accessCode != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.door_front_door_outlined, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text("Apto $aptNum", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                const Spacer(),
                
                if (hasCode)
                   InkWell(
                     onTap: () => _manageCode(tower, aptNum),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade200)),
                       child: Row(children: [
                         const Icon(Icons.lock_open, size: 14, color: Colors.green),
                         const SizedBox(width: 4),
                         Text(aptData!.accessCode!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                       ]),
                     ),
                   )
                else
                   IconButton(
                     icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                     tooltip: "Crear Código",
                     constraints: const BoxConstraints(),
                     padding: EdgeInsets.zero,
                     onPressed: () => _manageCode(tower, aptNum),
                   ),

                const SizedBox(width: 15),

                IconButton(
                  icon: const Icon(Icons.local_shipping_outlined, color: Colors.grey),
                  tooltip: "Mudanza (Limpiar Apto)",
                   constraints: const BoxConstraints(),
                   padding: EdgeInsets.zero,
                  onPressed: () => _processMoveOut(tower, aptNum, residents),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white),
          
          if (residents.isEmpty)
             const Padding(padding: EdgeInsets.all(10), child: Text("Sin residentes registrados", style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
             ...residents.map((user) => _buildResidentRow(user)),
             
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildResidentRow(User user) {
    final isActive = user.isActive ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(isActive ? Icons.check : Icons.block, size: 12, color: isActive ? Colors.green : Colors.red),
        ),
        title: Text(
          user.name ?? "Sin nombre",
          style: TextStyle(
            decoration: isActive ? null : TextDecoration.lineThrough,
            color: isActive ? const Color(0xFF0F172A) : Colors.grey,
            fontWeight: FontWeight.w500
          ),
        ),
        trailing: Switch(
          value: isActive,
          activeColor: Colors.green,
          onChanged: (val) => _toggleResidentStatus(user),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No se encontraron resultados", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(user.name ?? ""),
            subtitle: Text("${user.tower} - ${user.unit}"),
            trailing: Switch(
              value: user.isActive ?? true,
              onChanged: (val) => _toggleResidentStatus(user),
            ),
          ),
        );
      },
    );
  }
}