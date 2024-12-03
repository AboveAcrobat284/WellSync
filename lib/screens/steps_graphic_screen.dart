import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'chat_screen.dart';
import 'community_screen.dart';
import 'graphics_screen.dart';
import 'my_profile_screen.dart';

class StepsGraphicScreen extends StatefulWidget {
  final String userUuid;
  final String leadUuid;

  const StepsGraphicScreen({super.key, required this.userUuid, required this.leadUuid});

  @override
  _StepsGraphicScreenState createState() => _StepsGraphicScreenState();
}

class _StepsGraphicScreenState extends State<StepsGraphicScreen> {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initializePedometer();
  }

  // Verificar permisos para acceder al sensor de pasos
  Future<void> _checkPermissions() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _initializePedometer();
    } else {
      // Manejo de errores si el permiso no se concede
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El permiso de actividad no ha sido concedido.")),
      );
    }
  }

  // Inicialización del pedómetro para contar los pasos
  void _initializePedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen((StepCount event) {
      setState(() {
        _steps = event.steps;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Aquí observarás los pasos transcurridos durante el día",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Pasos",
              style: TextStyle(
                fontSize: 21,
                color: Color.fromRGBO(134, 134, 134, 1),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "$_steps",
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        "Distancia",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(134, 134, 134, 1),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: "7,432", 
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: " m",
                              style: TextStyle(
                                color: Color.fromRGBO(134, 134, 134, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 30),
                  Column(
                    children: [
                      Text(
                        "Calorías",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(134, 134, 134, 1),
                        ),
                      ),
                      Text(
                        "5,842",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Lun');
                            case 1:
                              return const Text('Mar');
                            case 2:
                              return const Text('Mié');
                            case 3:
                              return const Text('Jue');
                            case 4:
                              return const Text('Vie');
                            case 5:
                              return const Text('Sáb');
                            case 6:
                              return const Text('Dom');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(width: 1),
                      bottom: BorderSide(width: 1),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _createSampleData(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: _createPredictionData(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: _createConfidenceIntervalData(),
                      isCurved: false,
                      color: Colors.grey.withOpacity(0.3),
                      barWidth: 0,
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBarWithAnimation(
        selectedIndex: 2, 
        userUuid: widget.userUuid,
        leadUuid: widget.leadUuid,
      ),
    );
  }

  List<FlSpot> _createSampleData() {
    return [
      FlSpot(0, 5000),
      FlSpot(1, 7000),
      FlSpot(2, 8000),
      FlSpot(3, 7500),
      FlSpot(4, 9000),
      FlSpot(5, 8500),
      FlSpot(6, 9500),
    ];
  }

  List<FlSpot> _createPredictionData() {
    return [
      FlSpot(0, 10200),
      FlSpot(1, 11000),
      FlSpot(2, 11500),
      FlSpot(3, 12000),
      FlSpot(4, 11800),
      FlSpot(5, 12500),
      FlSpot(6, 13000),
    ];
  }

  List<FlSpot> _createConfidenceIntervalData() {
    List<FlSpot> confidenceData = [];
    List<FlSpot> actualData = _createSampleData();
    List<FlSpot> predictionData = _createPredictionData();

    for (int i = 0; i < actualData.length; i++) {
      double minValue = actualData[i].y < predictionData[i].y ? actualData[i].y : predictionData[i].y;
      confidenceData.add(FlSpot(i.toDouble(), minValue));
    }

    List<FlSpot> reverseConfidenceData = [];
    for (int i = actualData.length - 1; i >= 0; i--) {
      double maxValue = actualData[i].y > predictionData[i].y ? actualData[i].y : predictionData[i].y;
      reverseConfidenceData.add(FlSpot(i.toDouble(), maxValue));
    }

    confidenceData.addAll(reverseConfidenceData);
    return confidenceData;
  }
}
// Barra de navegación inferior con animación
class _BottomNavigationBarWithAnimation extends StatefulWidget {
  final int selectedIndex;
  final String userUuid;
  final String leadUuid;

  const _BottomNavigationBarWithAnimation({
    Key? key,
    required this.selectedIndex,
    required this.userUuid,
    required this.leadUuid,
  }) : super(key: key);

  @override
  __BottomNavigationBarWithAnimationState createState() =>
      __BottomNavigationBarWithAnimationState();
}

class __BottomNavigationBarWithAnimationState extends State<_BottomNavigationBarWithAnimation> {
  int _selectedIndex = 0;

  final List<IconData> _icons = [
    Icons.home,
    Icons.chat_bubble_outline,
    Icons.show_chart,
    Icons.group_outlined,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userUuid: widget.userUuid,
            leadUuid: widget.leadUuid,
          ),
        ),
      );
    } else if (index == 2) {
      if (_selectedIndex != 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GraphicsScreen(
              userUuid: widget.userUuid,
              leadUuid: widget.leadUuid,
            ),
          ),
        );
      }
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(
            userUuid: widget.userUuid,
            leadUuid: widget.leadUuid,
          ),
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyProfileScreen(
            userUuid: widget.userUuid,
            leadUuid: widget.leadUuid,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _icons.asMap().entries.map((entry) {
              int index = entry.key;
              IconData icon = entry.value;
              bool isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            left: MediaQuery.of(context).size.width * (_selectedIndex / _icons.length) +
                MediaQuery.of(context).size.width / _icons.length / 2 -
                35,
            top: 0,
            child: ClipPath(
              clipper: SmoothUShapeClipper(),
              child: Container(
                color: Colors.white,
                width: 70,
                height: 50,
                alignment: Alignment.center,
                child: Icon(
                  _icons[_selectedIndex],
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ClipPath personalizado para la "U"
class SmoothUShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.moveTo(0, size.height * 0);
    path.quadraticBezierTo(size.width * 0.2, size.height, size.width * 0.5, size.height);
    path.quadraticBezierTo(size.width * 0.8, size.height, size.width, size.height * 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
