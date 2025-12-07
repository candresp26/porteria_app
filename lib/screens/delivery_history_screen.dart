import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../models/ModelProvider.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  List<Package> _deliveredPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveredPackages();
  }

  Future<void> _fetchDeliveredPackages() async {
    setState(() => _isLoading = true);
    try {
      // Query manual para traer datos profundos (Apto, Torre, etc.)
      const graphQLDocument = '''
        query ListPackagesDelivered {
          listPackages(filter: {status: {eq: DELIVERED}}) {
            items {
              id
              courier
              updatedAt
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

        List<Package> loaded = items.map((item) => Package.fromJson(item)).toList();

        // Ordenar por fecha de actualización (el momento en que se entregó) descendente
        loaded.sort((a, b) {
           final dateA = a.updatedAt ?? TemporalDateTime.now();
           final dateB = b.updatedAt ?? TemporalDateTime.now();
           return dateB.compareTo(dateA);
        });

        setState(() {
          _deliveredPackages = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error historial: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Entregas"),
        backgroundColor: Colors.green[700], // Verde para diferenciar del inventario
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveredPackages.isEmpty
              ? const Center(child: Text("No hay entregas registradas aún."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _deliveredPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = _deliveredPackages[index];
                    final date = DateTime.parse(pkg.updatedAt.toString()).toLocal();
                    final dateStr = DateFormat('dd MMM - hh:mm a').format(date);
                    
                    final apto = pkg.recipient?.apartment;
                    final infoApto = apto != null ? "${apto.unitNumber} ${apto.tower}" : "Sin datos";
                    final vecino = pkg.recipient?.name ?? "Vecino";

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: const Icon(Icons.check, color: Colors.green),
                        ),
                        title: Text(
                          infoApto, 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Text("$vecino - $dateStr"),
                        trailing: Text(
                          pkg.courier,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}