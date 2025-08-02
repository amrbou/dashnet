import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TrafficCablePage extends StatelessWidget {
  const TrafficCablePage({super.key});

  Future<List<dynamic>> fetchTrafficCable() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/trafic_cable'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des données');
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicateurs = [
      'Bande_Passante_BPI',
      'INT_UTIL_>=90%_BPI',
      'Trafic_Max_IN_BPI',
      'Tx_Charge_Cable_BPI'
    ];
    return FutureBuilder<List<dynamic>>(
      future: fetchTrafficCable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune donnée'));
        } else {
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: indicateurs.map((name) {
              final item = data.firstWhere(
                (e) => (e['indicateur'] ?? '') == name,
                orElse: () => null,
              );
              if (item == null) return SizedBox.shrink();
              String displayName = item['indicateur'];
              if (displayName == 'INT_UTIL_>=90%_BPI') {
                displayName = "Interfaces utilisées ≥ 90% (BPI)";
              }
              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item['valeur'].toString(),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Date : ${item['date'].toString().split('T').first}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
}