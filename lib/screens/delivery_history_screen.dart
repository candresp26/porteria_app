import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:intl/intl.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  List<Map<String, dynamic>> _allDelivered = [];
  List<Map<String, dynamic>> _filteredDelivered = [];
  
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDeliveredPackages();
  }

  Future<void> _fetchDeliveredPackages() async {
    setState(() => _isLoading = true);
    try {
      // Query Manual para traer deliveryMethod y datos anidados
      const graphQLDocument = '''
        query ListPackagesDelivered {
          listPackages(filter: {status: {eq: DELIVERED}}, limit: 100) {
            items {
              id
              courier
              updatedAt
              receivedAt
              deliveryMethod 
              recipient {
                name
                apartment {
                  tower
                  unitNumber
                }
              }
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final Map<String, dynamic> data = json.decode(response.data!);
        final List items = data['listPackages']['items'];

        List<Map<String, dynamic>> cleanList = List<Map<String, dynamic>>.from(
          items.where((element) => element != null)
        );

        // Ordenar: Más recientes primero
        cleanList.sort((a, b) {
           final String dateStrA = a['updatedAt'] ?? a['receivedAt'] ?? "";
           final String dateStrB = b['updatedAt'] ?? b['receivedAt'] ?? "";
           return dateStrB.compareTo(dateStrA);
        });

        setState(() {
          _allDelivered = cleanList;
          _filteredDelivered = cleanList; 
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error historial: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Buscador local
  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allDelivered;
    } else {
      results = _allDelivered.where((pkg) {
        String tower = "";
        String unit = "";
        
        if (pkg['recipient'] != null && pkg['recipient']['apartment'] != null) {
           tower = (pkg['recipient']['apartment']['tower'] ?? "").toString().toLowerCase();
           unit = (pkg['recipient']['apartment']['unitNumber'] ?? "").toString().toLowerCase();
        }
        final search = keyword.toLowerCase();
        return unit.contains(search) || tower.contains(search);
      }).toList();
    }
    setState(() {
      _filteredDelivered = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial (Últimos 100)"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDeliveredPackages)
        ],
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                labelText: 'Buscar por Apto (ej: 101)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _runFilter('');
                      },
                    ) 
                  : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // LISTA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDelivered.isEmpty
                    ? const Center(child: Text("No se encontraron entregas.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: _filteredDelivered.length,
                        itemBuilder: (context, index) {
                          final pkg = _filteredDelivered[index];
                          
                          // 1. Datos básicos
                          final String fechaRaw = pkg['updatedAt'] ?? pkg['receivedAt'] ?? "";
                          String dateStr = "--";
                          if (fechaRaw.isNotEmpty) {
                            try {
                              final date = DateTime.parse(fechaRaw).toLocal();
                              dateStr = DateFormat('dd MMM - hh:mm a').format(date);
                            } catch (_) {}
                          }

                          String infoApto = "Desconocido";
                          String vecino = "Vecino";
                          if (pkg['recipient'] != null) {
                            vecino = pkg['recipient']['name'] ?? "Vecino";
                            if (pkg['recipient']['apartment'] != null) {
                              final t = pkg['recipient']['apartment']['tower'] ?? "?";
                              final u = pkg['recipient']['apartment']['unitNumber'] ?? "?";
                              infoApto = "$u - $t";
                            }
                          }

                          // 2. Lógica del Icono según Método de Entrega
                          IconData iconData = Icons.help_outline;
                          Color iconColor = Colors.grey;
                          String method = pkg['deliveryMethod'] ?? "UNKNOWN";

                          if (method == "MANUAL_NO_SIGNATURE") {
                            iconData = Icons.warning_amber_rounded;
                            iconColor = Colors.red;
                          } else if (method == "MANUAL_WITH_SIGNATURE") {
                            iconData = Icons.draw;
                            iconColor = Colors.orange;
                          } else if (method == "QR_WITH_SIGNATURE") {
                            iconData = Icons.qr_code_2;
                            iconColor = Colors.green;
                          } else if (method == "DELIVERED") {
                             // Caso legacy (datos viejos)
                             iconData = Icons.check;
                             iconColor = Colors.blue;
                          }

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Icon(iconData, color: iconColor),
                              ),
                              title: Text(infoApto, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("$vecino\n$dateStr", style: const TextStyle(fontSize: 12)),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                                  Text(pkg['courier'] ?? "", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}