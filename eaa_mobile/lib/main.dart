import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'throughput_vendor_page.dart';
import 'traffic_cable_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(DashNetApp());
}

class DashNetApp extends StatelessWidget {
  const DashNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashNet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF181C20), // gris foncé sobre
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPage = 'network_synthese';
  String? _selectedCountry;

  void _navigate(String page) {
    setState(() {
      _selectedPage = page;
      Navigator.pop(context); 
    });
  }

  Widget _getPageContent() {
    if (_selectedPage == 'network_synthese') {
      return FutureBuilder<List<dynamic>>(
        future: fetchNetworkSynthese(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aucune donnée'));
          } else {
            final data = snapshot.data!;
            final inscritsVlr = data.firstWhere(
              (e) => (e['indicateur'] ?? '') == 'Inscrits VLR [M]',
              orElse: () => null,
            );
            final attaches = data.firstWhere(
              (e) => (e['indicateur'] ?? '') == 'Attaches simultanes',
              orElse: () => null,
            );
            final debit4g = data.firstWhere(
              (e) => (e['indicateur'] ?? '') == 'Debit_4G [Mbps]',
              orElse: () => null,
            );
            final throughput = data.firstWhere(
              (e) => (e['indicateur'] ?? '') == 'Throughput Mobile [Gbps]',
              orElse: () => null,
            );

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (inscritsVlr != null)
                  _indicatorCard(inscritsVlr['indicateur'], inscritsVlr['valeur'], inscritsVlr['date']),
                if (attaches != null)
                  _indicatorCard(attaches['indicateur'], attaches['valeur'], attaches['date']),
                if (debit4g != null)
                  _gaugeCard(debit4g['indicateur'], debit4g['valeur'], debit4g['date']),
                if (throughput != null)
                  _gaugeCard(throughput['indicateur'], throughput['valeur'], throughput['date']),

                // Affiche tous les autres indicateurs distincts restants
                ...data.where((item) {
                  final ind = item['indicateur'] ?? '';
                  return ![
                    'Inscrits VLR [M]',
                    'Attaches simultanes',
                    'Debit_4G [Mbps]',
                    'Throughput Mobile [Gbps]'
                  ].contains(ind);
                }).map((item) {
                  final ind = (item['indicateur'] ?? '').toString();
                  // Affiche une gauge si l'indicateur est numérique pertinent
                  if (ind.contains('Mbps') ||
                      ind.contains('Gbps') ||
                      ind.contains('%') ||
                      ind.toLowerCase().contains('poids')) {
                    return _gaugeCard(item['indicateur'], item['valeur'], item['date']);
                  }
                  // Sinon, affichage comme _indicatorCard
                  return _indicatorCard(item['indicateur'], item['valeur'], item['date']);
                }),
              ],
            );
          }
        },
      );
    } else if (_selectedPage == 'bpi_traffic') {
      return FutureBuilder<List<dynamic>>(
        future: fetchBpiTraffic(), // <-- doit pointer sur /bpi_traffic
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
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.map),
                  label: Text('Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    // Pour la map, on va chercher les données groupées par pays
                    final mapData = await fetchBpiTrafficByCountry();
                    showDialog(
                      context: context,
                      builder: (context) => BpiTrafficMapDialog(data: mapData),
                    );
                  },
                ),
                SizedBox(height: 16),
                ...data.map((item) =>
                  _indicatorCard(item['indicateur'], item['valeur'], item['date'])
                ),
              ],
            );
          }
        },
      );
    } else if (_selectedPage == 'throughput vendor') {
      return ThroughputVendorPage();
    } else if (_selectedPage == 'traffic_cable') {
      return TrafficCablePage();
    }
    return Center(
      child: Text(
        _selectedPage.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget pour afficher un indicateur sous forme de carte
  Widget _indicatorCard(String indicateur, dynamic valeur, dynamic date) {
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
              indicateur,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            SizedBox(height: 8),
            Text(
              valeur.toString(),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
            ),
            SizedBox(height: 6),
            Text(
              'Date : ${date.toString().split('T').first}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // Widget compact pour chaque indicateur
  Widget _compactIndicator(String indicateur, dynamic valeur, dynamic date) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            indicateur,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            valeur.toString(),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
          ),
          SizedBox(height: 4),
          Text(
            date.toString().split('T').first,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _gaugeCard(String indicateur, dynamic valeur, dynamic date) {
    double doubleValue = 0;
    try {
      doubleValue = double.tryParse(valeur.toString()) ?? 0;
    } catch (_) {}

    // Définir les bornes pour les couleurs (adapte selon tes besoins)
    double max = (doubleValue * 1.5).clamp(1, 100);
    double orangeLimit = max * 0.6;
    double greenLimit = max * 0.85;

    // Déduire l'unité à partir du nom de l'indicateur
    String unite = '';
    if (indicateur.contains('Gbps')) unite = 'Gbps';
    if (indicateur.contains('Mbps')) unite = 'Mbps';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400], // BLEU sobre
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              indicateur,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: max,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.2,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: 0,
                      endValue: orangeLimit,
                      color: Colors.blue.shade700,
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                    GaugeRange(
                      startValue: orangeLimit,
                      endValue: greenLimit,
                      color: Colors.blue.shade400,
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                    GaugeRange(
                      startValue: greenLimit,
                      endValue: max,
                      color: Colors.blue.shade200,
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(value: doubleValue, needleColor: Colors.white),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$valeur',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (unite.isNotEmpty)
                            Text(
                              unite,
                              style: TextStyle(fontSize: 18, color: Colors.white70),
                            ),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.7,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Date : $date',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gaugeCardWithSource(String indicateur, dynamic valeur, dynamic date, String source) {
    double doubleValue = 0;
    try {
      doubleValue = double.tryParse(valeur.toString()) ?? 0;
    } catch (_) {}

    // Définir les bornes pour les couleurs (adapte selon tes besoins)
    double max = (doubleValue * 1.5).clamp(1, 100);
    double orangeLimit = max * 0.6;
    double greenLimit = max * 0.85;

    // Déduire l'unité à partir du nom de l'indicateur
    String unite = '';
    if (indicateur.contains('Gbps')) unite = 'Gbps';
    if (indicateur.contains('Mbps')) unite = 'Mbps';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400], // BLEU sobre
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              indicateur,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: max,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.2,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: 0,
                      endValue: orangeLimit,
                      color: Colors.blue.shade700,
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                    GaugeRange(
                      startValue: orangeLimit,
                      endValue: greenLimit,
                      color: Colors.blue.shade400,
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                    GaugeRange(
                      startValue: greenLimit,
                      endValue: max,
                      color: Colors.blue.shade200,
                      startWidth: 0.2,
                      endWidth: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(value: doubleValue, needleColor: Colors.white),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$valeur',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (unite.isNotEmpty)
                            Text(
                              unite,
                              style: TextStyle(fontSize: 18, color: Colors.white70),
                            ),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.7,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Date : $date',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'Source : $source',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DashNet'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
              ),
              child: Center(
                child: Text(
                  'DashNet',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _drawerItem('network_synthese', Icons.network_check),
            _drawerItem('bpi_traffic', Icons.traffic),
            _drawerItem('throughput vendor', Icons.speed),
            _drawerItem('traffic_cable', Icons.cable),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _getPageContent(),
      ),
    );
  }

  Widget _drawerItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title.replaceAll('_', ' '),
        style: TextStyle(fontSize: 16),
      ),
      selected: _selectedPage == title,
      selectedTileColor: Colors.blue.shade100,
      onTap: () => _navigate(title),
    );
  }
}

Future<List<dynamic>> fetchNetworkSynthese() async {
  final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/network'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Erreur lors du chargement des données');
  }
}

Future<List<dynamic>> fetchBpiTraffic() async {
  final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/bpi_traffic'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Erreur lors du chargement des données');
  }
}

Future<List<dynamic>> fetchBpiTrafficByCountry() async {
  final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/bpi_traffic/by_country'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Erreur lors du chargement des données');
  }
}

final Map<String, LatLng> countryCoords = {
  'MOOV-AFRICA-BENIN': LatLng(9.3077, 2.3158),
  'MOOV-AFRICA-BURKINA': LatLng(12.2383, -1.5616),
  'MOOV-AFRICA-CI': LatLng(7.539989, -5.54708),
  'MOOV-AFRICA-GABON': LatLng(-0.8037, 11.6094),
  'MOOV-AFRICA-MALITEL': LatLng(17.5707, -3.9962),
  'MOOV-AFRICA-TOGO': LatLng(8.6195, 0.8248),
};

class BpiTrafficMapDialog extends StatelessWidget {
  final List<dynamic> data;
  const BpiTrafficMapDialog({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<dynamic>> indicateursByCountry = {};
    for (final country in countryCoords.keys) {
      indicateursByCountry[country] = data.where((e) => (e['source'] ?? '') == country).toList();
    }

    return AlertDialog(
      title: Text('BPI Traffic Map'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 400,
        child: _MapWithBottomSheet(indicateursByCountry: indicateursByCountry),
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

class _MapWithBottomSheet extends StatefulWidget {
  final Map<String, List<dynamic>> indicateursByCountry;
  const _MapWithBottomSheet({required this.indicateursByCountry});

  @override
  State<_MapWithBottomSheet> createState() => _MapWithBottomSheetState();
}

class _MapWithBottomSheetState extends State<_MapWithBottomSheet> {
  double zoom = 3.5;
  final mapController = MapController();

  void setZoom(double newZoom) {
    setState(() {
      zoom = newZoom;
      mapController.move(mapController.center, zoom);
    });
  }

  Widget _indicatorCard(String indicateur, dynamic valeur, dynamic date) {
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
              indicateur,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            SizedBox(height: 8),
            Text(
              valeur.toString(),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
            ),
            SizedBox(height: 6),
            Text(
              'Date : ${date.toString().split('T').first}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: LatLng(7.5, 2.5),
            zoom: zoom,
            interactiveFlags: InteractiveFlag.all,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: countryCoords.entries.map((entry) {
                final country = entry.key;
                final coord = entry.value;
                return Marker(
                  width: 40,
                  height: 40,
                  point: coord,
                  child: GestureDetector(
                    onTap: () {
                      final indicateurs = widget.indicateursByCountry[country] ?? [];
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    country.replaceAll('MOOV-AFRICA-', ''),
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 12),
                                  if (indicateurs.isEmpty)
                                    Text('Aucune donnée', style: TextStyle(fontSize: 16)),
                                  ...indicateurs.map((item) => _indicatorCard(
                                        item['indicateur'],
                                        item['valeur'],
                                        item['date'],
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        country.replaceAll('MOOV-AFRICA-', '').substring(0, 2),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'zoomIn',
                backgroundColor: Colors.blue.shade900,
                child: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  setZoom((zoom + 0.5).clamp(2.0, 18.0));
                },
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'zoomOut',
                backgroundColor: Colors.blue.shade900,
                child: Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  setZoom((zoom - 0.5).clamp(2.0, 18.0));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final paysList = [
  'MOOV-AFRICA-BENIN',
  'MOOV-AFRICA-BURKINA',
  'MOOV-AFRICA-CI',
  'MOOV-AFRICA-GABON',
  'MOOV-AFRICA-MALITEL',
  'MOOV-AFRICA-TOGO',
];
