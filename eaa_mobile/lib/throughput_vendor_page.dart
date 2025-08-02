import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ThroughputVendorPage extends StatelessWidget {
  const ThroughputVendorPage({super.key});

  Future<List<dynamic>> fetchThroughputVendor() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/throughput'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des données');
    }
  }

  Future<List<dynamic>> fetchThroughputTrend(String indicateur, String source) async {
    final response = await http.get(Uri.parse(
      'http://10.0.2.2:3000/api/throughput/trend?indicateur=${Uri.encodeComponent(indicateur)}&source=${Uri.encodeComponent(source)}'
    ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement du trend');
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicateurs = [
      'Debit_3G [Mbps]',
      'Debit_3G_BH [Mbps]',
      'Debit_4G [Mbps]',
      'Debit_4G_BH [Mbps]'
    ];
    return FutureBuilder<List<dynamic>>(
      future: fetchThroughputVendor(),
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
              final items = data.where((e) => (e['indicateur'] ?? '') == name).toList();
              if (items.isEmpty) return SizedBox.shrink();

              final allSources = ['Huawei', 'Ericsson', 'Nokia'];

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      SizedBox(height: 8),
                      ...allSources.map((source) {
                        final item = items.firstWhere(
                          (e) => (e['source'] ?? '').toString().toLowerCase().contains(source.toLowerCase()),
                          orElse: () => null,
                        );
                        String? sourceImg;
                        final sourceLower = source.toLowerCase();
                        if (sourceLower.contains('huawei')) sourceImg = 'assets/huawei.png';
                        if (sourceLower.contains('ericsson')) sourceImg = 'assets/ericsson.png';
                        if (sourceLower.contains('nokia')) sourceImg = 'assets/nokia.png';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (item != null && sourceImg != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0, top: 4),
                                child: Image.asset(sourceImg, width: 32, height: 32),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    source,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                  ),
                                  if (item != null) ...[
                                    Text(
                                      item['valeur'].toString(),
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                    ),
                                    Text(
                                      'Date : ${item['date'].toString().split('T').first}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  ] else ...[
                                    Text('-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                                    Text('Aucune donnée', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                  ],
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.show_chart),
                                      label: Text('Voir la trend'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade900,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        textStyle: TextStyle(fontSize: 14),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return ThroughputTrendDialog(
                                              indicateur: name,
                                              source: source,
                                              fetchTrend: fetchThroughputTrend,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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

class ThroughputTrendDialog extends StatelessWidget {
  final String indicateur;
  final String source;
  final Future<List<dynamic>> Function(String, String) fetchTrend;

  const ThroughputTrendDialog({
    required this.indicateur,
    required this.source,
    required this.fetchTrend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Trend - $indicateur ($source)'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 350,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF181F2A),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(24),
          child: FutureBuilder<List<dynamic>>(
            future: fetchTrend(indicateur, source),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('Aucune donnée');
              } else {
                final data = snapshot.data!;
                final maxPoints = 30;
                final step = (data.length / maxPoints).ceil();
                final spots = <FlSpot>[];
                for (int i = 0; i < data.length; i += step) {
                  final val = double.tryParse(data[i]['valeur'].toString()) ?? 0;
                  spots.add(FlSpot(spots.length.toDouble(), val));
                }
                return LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: const Color.fromARGB(255, 29, 213, 226),
                        dotData: FlDotData(show: false),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('Mbps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        axisNameSize: 32, 
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (spots.isNotEmpty)
                              ? ((spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) -
                                  spots.map((e) => e.y).reduce((a, b) => a < b ? a : b)) /
                                  4)
                              : 1,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        axisNameSize: 32, 
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (spots.length / 4).ceilToDouble().clamp(1, double.infinity),
                          getTitlesWidget: (value, meta) {
                            int idx = value.round();
                            if (spots.length <= 1 || idx < 0 || idx >= spots.length) return Container();
                            int labelStep = (spots.length / 4).ceil();
                            if (idx % labelStep != 0 && idx != spots.length - 1) return Container();
                            int dataIdx = idx * step;
                            if (dataIdx >= data.length) dataIdx = data.length - 1;
                            String date = data[dataIdx]['date'].toString().split('T').first;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                date.substring(5), 
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                    borderData: FlBorderData(show: true),
                    minY: spots.isNotEmpty ? (spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95).floorToDouble() : 0,
                    maxY: spots.isNotEmpty ? (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05).ceilToDouble() : 1,
                    lineTouchData: LineTouchData(enabled: true),
                    clipData: FlClipData.all(),
                  ),
                );
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Fermer'),
        ),
      ],
    );
  }
}