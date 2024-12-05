import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  List<FlSpot> realData = [];
  List<FlSpot> predictedData = [];
  List<FlSpot> confidenceInterval = []; // Único intervalo de confianza combinado

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

    // Una vez que se carga el UUID, hacer el GET a la API
    if (userUuid != null) {
      await fetchEmotionData();
    }
  }

  Future<void> fetchEmotionData() async {
    if (userUuid == null) return;

    final url = Uri.parse(
        'https://0dqw4sfw-5000.usw3.devtunnels.ms/api/emociones?useruuid=$userUuid');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Obtener las emociones predichas
        List<String> emociones = List<String>.from(data['prediccion']['emocion']);
        
        // Obtener los intervalos de confianza
        List<List<int>> intervalosConfianza = (data['prediccion']['intervalos_confianza'] as List)
            .map((e) => List<int>.from(e as List))
            .toList();
        
        // Obtener los sentimientos registrados
        List<String> sentimientos = List<String>.from(data['sentimientos_registrados']);

        // Convertir las emociones predichas y los intervalos de confianza a FlSpots
        setState(() {
          realData = _convertToFlSpots(sentimientos); // Sentimientos registrados (línea verde)
          predictedData = _convertToFlSpots(emociones); // Emociones predichas (línea azul)
          confidenceInterval = _convertConfidenceIntervalToFlSpots(intervalosConfianza); // Intervalo combinado
        });
      } else {
        throw Exception('Error al obtener los datos');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Función para convertir las emociones o sentimientos registrados a FlSpot
  List<FlSpot> _convertToFlSpots(List<String> emociones) {
    const emocionesMap = {
      'aburrido': 0.0,
      'nervioso': 1.0,
      'neutral': 2.0,
      'triste': 3.0,
      'enojado': 4.0,
      'feliz': 5.0,
    };

    List<FlSpot> spots = [];
    for (int i = 0; i < emociones.length; i++) {
      if (emocionesMap.containsKey(emociones[i])) {
        spots.add(FlSpot(i.toDouble(), emocionesMap[emociones[i]]!));
      }
    }
    return spots;
  }

  // Función para convertir los intervalos de confianza a FlSpot
  List<FlSpot> _convertConfidenceIntervalToFlSpots(List<List<int>> intervalosConfianza) {
    List<FlSpot> spots = [];
    
    // Suponiendo que intervalosConfianza[0] es el intervalo superior y intervalosConfianza[1] es el intervalo inferior
    for (int i = 0; i < intervalosConfianza[0].length; i++) {
      double lower = intervalosConfianza[1][i].toDouble(); // Intervalo inferior
      double upper = intervalosConfianza[0][i].toDouble(); // Intervalo superior
      // El punto medio será el valor central del intervalo de confianza
      double middle = (lower + upper) / 2;
      spots.add(FlSpot(i.toDouble(), middle)); // Puntos medios para el sombreado
    }
    return spots;
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
              "Aquí podrás observar la gráfica conforme a tu humor durante el transcurso de la semana, la linea azul son las predicciones para tu proxima semana, la verde son las emociones que registraste en la semana y la sombra azul es nuestro intervalo de confianza.",
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
                          const emojis = ['😴', '😰', '😐', '😭', '😡', '😁'];
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
                    // Gráfico de emociones reales (Línea verde)
                    LineChartBarData(
                      spots: realData,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Gráfico de emociones predichas (Línea azul)
                    LineChartBarData(
                      spots: predictedData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Sombreado del intervalo de confianza (curvado)
                    LineChartBarData(
                      spots: confidenceInterval,
                      isCurved: true,
                      color: Colors.blue.withOpacity(0.3), // Color del sombreado
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                      barWidth: 1,
                    ),
                  ],
                  minY: 0,  // Establece el límite inferior del eje Y
                  maxY: 5,  // Establece el límite superior del eje Y
                  maxX: 6,  // Establece el límite superior del eje X (7 días)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
