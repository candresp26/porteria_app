import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/ModelProvider.dart';

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  bool _isLoading = false;
  List<Apartment> _apartments = [];
  List<Apartment> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final req = ModelQueries.list(Apartment.classType);
      final res = await Amplify.API.query(request: req).response;
      if (res.data != null) {
        final data = res.data!.items.whereType<Apartment>().toList();
        
        // Ordenar primero por Torre, luego por Número
        data.sort((a, b) {
            int cmp = a.tower.compareTo(b.tower);
            if (cmp != 0) return cmp;
            return a.unitNumber.compareTo(b.unitNumber);
        });

        setState(() {
          _apartments = data;
          _filtered = data;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter(String q) {
    setState(() => _filtered = _apartments.where((a) => a.unitNumber.contains(q) || a.tower.toLowerCase().contains(q.toLowerCase())).toList());
  }

  // --- HELPER PARA FECHAS (Evita el RangeError) ---
  String _formatExpiry(TemporalDateTime? date) {
    if (date == null) return "Sin fecha";
    try {
      // Convertimos a fecha real de Dart
      final d = DateTime.parse(date.toString()).toLocal();
      // Formateamos manualmente sin usar substring peligroso
      return "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Error fecha";
    }
  }

  Future<void> _manageCode(Apartment apt, {bool revoke = false}) async {
    setState(() => _isLoading = true);
    try {
      String? newCode;
      TemporalDateTime? expires;
      
      if (!revoke) {
        newCode = (Random().nextInt(900000) + 100000).toString(); // 6 dígitos
        expires = TemporalDateTime(DateTime.now().add(const Duration(hours: 24)));
      }

      final updatedApt = Apartment(
        id: apt.id,
        tower: apt.tower,
        unitNumber: apt.unitNumber,
        maxResidents: apt.maxResidents,
        accessCode: newCode,
        codeExpiresAt: expires
      );

      await Amplify.API.mutate(request: ModelMutations.update(updatedApt)).response;
      _fetchData(); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(revoke ? "Código eliminado" : "Nuevo código generado: $newCode"),
          backgroundColor: revoke ? Colors.red : Colors.green,
        ));
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ARREGLO 1: Scaffold evita el error "No Material widget"
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), 
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Buscar apartamento...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty 
              ? const Center(child: Text("No se encontraron apartamentos"))
              : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final apt = _filtered[i];
                final hasCode = apt.accessCode != null;
                
                return Card(
                  child: ListTile(
                    leading: Icon(
                      hasCode ? Icons.lock_open : Icons.lock_outline,
                      color: hasCode ? Colors.green : Colors.grey
                    ),
                    title: Text("${apt.tower} - ${apt.unitNumber}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: hasCode 
                      // 🔥 ARREGLO 2: Usamos _formatExpiry en vez de substring
                      ? Text("Código: ${apt.accessCode}\nVence: ${_formatExpiry(apt.codeExpiresAt)}")
                      : const Text("Sin código de acceso"),
                    trailing: hasCode
                      ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _manageCode(apt, revoke: true))
                      : IconButton(icon: const Icon(Icons.add_circle, color: Colors.indigo), onPressed: () => _manageCode(apt)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}