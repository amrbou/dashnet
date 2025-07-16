import 'package:flutter/material.dart';

void main() {
  runApp(const NetworkApp());
}

class NetworkApp extends StatelessWidget {
  const NetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primaryColor: Colors.blue[900],
        useMaterial3: true,
      ),
      home: const NetworkDashboard(),
    );
  }
}

class NetworkDashboard extends StatelessWidget {
  const NetworkDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final indicatorData = [
      {'label': 'Network Synthese', 'value': 'Stable'},
      {'label': 'BPI Traffic', 'value': '125 Mbps'},
      {'label': 'Traffic Cable', 'value': '300 Mbps'},
      {'label': 'Throughput Vendor', 'value': '89%'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicateurs Réseau'),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
            return Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: indicatorData.map((data) {
                  return IndicatorButton(
                    label: data['label']!,
                    value: data['value']!,
                    onTap: () {
                      debugPrint('${data['label']} clicked!');
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Custom Animated Indicator Button ---
class IndicatorButton extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const IndicatorButton({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  State<IndicatorButton> createState() => _IndicatorButtonState();
}

class _IndicatorButtonState extends State<IndicatorButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.05,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onEnter(bool hovering) {
    setState(() {
      _hovering = hovering;
    });
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(true),
      onExit: (_) => _onEnter(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 180,
                height: 120,
                decoration: BoxDecoration(
                  color: _hovering ? Colors.blue[700] : Colors.blue[800],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _hovering
                          ? Colors.blueAccent.withOpacity(0.6)
                          : Colors.black45,
                      blurRadius: _hovering ? 20 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
