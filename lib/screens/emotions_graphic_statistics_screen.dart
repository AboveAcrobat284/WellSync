import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmotionsGraphicStatisticsScreen extends StatefulWidget {
  const EmotionsGraphicStatisticsScreen({Key? key}) : super(key: key);

  @override
  _EmotionsGraphicStatisticsScreenState createState() =>
      _EmotionsGraphicStatisticsScreenState();
}

class _EmotionsGraphicStatisticsScreenState
    extends State<EmotionsGraphicStatisticsScreen> {
  String? userUuid;
  String? leadUuid;

  @override
  void initState() {
    super.initState();
    _loadUUIDs();
  }

  // Cargar los valores de SharedPreferences
  void _loadUUIDs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userUuid = prefs.getString('userUuid');
      leadUuid = prefs.getString('leadUuid');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si los datos no están cargados, mostrar un indicador de carga
    if (userUuid == null || leadUuid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40), // Espacio de 20 píxeles arriba del texto
            const Text(
              "Aquí podrás observar la gráfica conforme a tu humor durante el transcurso de la semana",
              style: TextStyle(
                fontSize: 17,
                color: Color.fromRGBO(0, 0, 0, 0.35),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Gráfica de emociones",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 0),
            // Gráfico de emociones con los emojis
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Emojis del eje Y (vertical)
                          const emojis = ['😁', '😰', '😭', '😐', '😴', '😡'];
                          int index = value.toInt();
                          if (index >= 0 && index < emojis.length) {
                            return Text(
                              emojis[index], // Usamos emojis según el valor del eje Y
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Días de la semana para el eje X (horizontal)
                          const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                          int index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(
                              days[index],
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            );
                          }
                          return const Text('');
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
                    // Gráfico de emociones reales (Línea azul)
                    LineChartBarData(
                      spots: _createSampleData(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Gráfico de emociones predichas (Línea verde)
                    LineChartBarData(
                      spots: _createPredictedData(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Sombra entre las líneas (Área entre las líneas)
                    LineChartBarData(
                      spots: _createShadedArea(),
                      isCurved: true,
                      color: Colors.green.withOpacity(0.3),
                      barWidth: 0,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                  ],
                  minY: 0,  // Establece el límite inferior del eje Y
                  maxY: 5,  // Establece el límite superior del eje Y (solo 6 valores)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Datos de ejemplo para la gráfica de emociones reales (emoción por día de la semana)
  List<FlSpot> _createSampleData() {
    return [
      FlSpot(0, 4),  // Lunes
      FlSpot(1, 3),  // Martes
      FlSpot(2, 2),  // Miércoles 
      FlSpot(3, 3),  // Jueves
      FlSpot(4, 4),  // Viernes
      FlSpot(5, 5),  // Sábado
      FlSpot(6, 1),  // Domingo
    ];
  }

  // Datos de ejemplo para la gráfica predicha
  List<FlSpot> _createPredictedData() {
    return [
      FlSpot(0, 3),  // Lunes
      FlSpot(1, 3.5),  // Martes
      FlSpot(2, 3.5),  // Miércoles 
      FlSpot(3, 4),  // Jueves
      FlSpot(4, 4.2),  // Viernes
      FlSpot(5, 4.5),  // Sábado
      FlSpot(6, 4.3),  // Domingo
    ];
  }

  // Crea el área sombreada entre las dos líneas (real y predicha)
  List<FlSpot> _createShadedArea() {
    List<FlSpot> shadedArea = [];
    List<FlSpot> realData = _createSampleData();
    List<FlSpot> predictedData = _createPredictedData();

    for (int i = 0; i < realData.length; i++) {
      // Añadimos el punto inferior de la sombra (real)
      shadedArea.add(FlSpot(realData[i].x, realData[i].y));
    }

    for (int i = realData.length - 1; i >= 0; i--) {
      // Añadimos el punto superior de la sombra (predicción)
      shadedArea.add(FlSpot(predictedData[i].x, predictedData[i].y));
    }

    return shadedArea;
  }
}
