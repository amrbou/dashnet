import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
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

  void _navigate(String page) {
    setState(() {
      _selectedPage = page;
      Navigator.pop(context); 
    });
  }

  Widget _getPageContent() {
    return Center(
      child: Text(
        _selectedPage.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                    color: Colors.white,
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
