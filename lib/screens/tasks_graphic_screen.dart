import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class TasksGraphicScreen extends StatefulWidget {
  const TasksGraphicScreen({Key? key}) : super(key: key);

  @override
  _TasksGraphicScreenState createState() => _TasksGraphicScreenState();
}

class _TasksGraphicScreenState extends State<TasksGraphicScreen> {
  String? userUuid;
  List<Map<String, dynamic>> tasksData = []; // Lista para almacenar los datos de la API
  List<FlSpot> completedTasksData = []; // Lista para los datos de tareas completadas
  List<FlSpot> incompleteTasksData = []; // Lista para los datos de tareas no completadas

  // Contadores
  int totalCompletedTasks = 0;  // Total de tareas completadas en la semana
  int totalIncompleteTasks = 0; // Total de tareas no completadas en la semana
  String mensaje = "";          // Mensaje personalizado

  @override
  void initState() {
    super.initState();
    _loadUUIDs(); // Cargar los UUIDs cuando se inicie la pantalla
  }

  // Método para cargar los UUIDs desde SharedPreferences
  void _loadUUIDs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userUuid = prefs.getString('userUuid');
    });
    // Llamar a la API para obtener las tareas del usuario
    if (userUuid != null) {
      _fetchTareas(userUuid!);
    }
  }

  // Método para hacer la solicitud HTTP a la API y obtener las tareas
  Future<void> _fetchTareas(String userUuid) async {
    final url = 'https://0dqw4sfw-3003.usw3.devtunnels.ms/api/v1/task/get/tareas/$userUuid';

    try {
      // Realizar la solicitud GET
      final response = await http.get(Uri.parse(url));

      // Verificar que la respuesta es exitosa (código 200)
      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        var data = jsonDecode(response.body);

        // Actualizamos la lista de tareas con los datos de la API
        setState(() {
          tasksData = List<Map<String, dynamic>>.from(data);
          _processGraphData();
        });
      } else {
        // Si la respuesta no fue exitosa, mostrar el código de error
        print('Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      // Manejo de errores en caso de que la solicitud falle
      print('Error al realizar la solicitud: $e');
    }
  }

  // Método para procesar los datos de las tareas y preparar las listas para la gráfica
  void _processGraphData() {
    List<FlSpot> completed = [];
    List<FlSpot> incomplete = [];
    
    double maxCompleted = 0; // Para encontrar el valor máximo de tareas completadas
    double maxIncomplete = 0; // Para encontrar el valor máximo de tareas no completadas

    totalCompletedTasks = 0;  // Reiniciar el contador de tareas completadas
    totalIncompleteTasks = 0; // Reiniciar el contador de tareas no completadas

    // Recorrer los datos de la API y llenar las listas de FlSpot
    for (int i = 0; i < tasksData.length; i++) {
      var task = tasksData[i];
      
      // Usar el índice como el día de la semana (0: lunes, 1: martes, ...)
      int dayIndex = i + 1; // Lunes empieza en 1, no en 0
      double completedCount = task['completedTasksCount'].toDouble();
      double incompleteCount = task['incompleteTasksCount'].toDouble();
      
      completed.add(FlSpot(dayIndex.toDouble(), completedCount));
      incomplete.add(FlSpot(dayIndex.toDouble(), incompleteCount));

      // Sumar las tareas completadas e incompletas
      totalCompletedTasks += completedCount.toInt();
      totalIncompleteTasks += incompleteCount.toInt();

      // Encontrar los valores máximos de tareas completadas e incompletas
      if (completedCount > maxCompleted) {
        maxCompleted = completedCount;
      }
      if (incompleteCount > maxIncomplete) {
        maxIncomplete = incompleteCount;
      }
    }

    // Establecer los datos de las tareas completadas y no completadas
    setState(() {
      completedTasksData = completed;
      incompleteTasksData = incomplete;
      
      // Ajustar el rango de la gráfica de acuerdo a los valores máximos
      double maxYValue = (maxCompleted > maxIncomplete) ? maxCompleted : maxIncomplete;
      _minY = 0;  // Límite inferior del gráfico
      _maxY = maxYValue + 2; // Añadir un pequeño margen para no recortar los valores más altos

      // Mensaje personalizado
    if (totalIncompleteTasks == 0) {
      mensaje = "¡Eres increíble!🎉\nMe alegro que cumplas todas tus tareas, sigue esforzándote día a día, cada día que cumples todas tus tareas estás un paso más cerca de ser la mejor versión de ti.💪";
    } else if (totalIncompleteTasks == 1) {
      mensaje = "Vaya...\nEs una lástima que no hayas cumplido con todas tus tareas de la semana, pero no te desanimes, Roma no se construyó en un día y cada día que pasa es una oportunidad más para mejorar.💪";
    } else if (totalCompletedTasks == totalIncompleteTasks) {  // Comparar completadas vs incompletas
      mensaje = "Vaya...\nTienes la misma cantidad de tareas incompletas y completas, hay que mejorar eso y que el número de tareas incompletas sea inferior.💪";
    } else {
      mensaje = "¡Sigue adelante! No te rindas. Aún puedes mejorar y cumplir con todas tus tareas esta semana.🏋️";
    }
    });
  }

  // Variables para los valores de minY y maxY
  double _minY = 0;
  double _maxY = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas de tus tareas"),
        elevation: 0,
      ),
      body: SingleChildScrollView( // Hacer que el cuerpo sea desplazable
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primer texto: "Aquí observarás las tareas completadas"
              Text(
                "Aquí observarás las tareas completadas durante la semana",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              // Row para "Tareas Completadas" y "Tareas No Completadas"
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Columna para "Tareas Completadas"
                    Column(
                      children: [
                        Text(
                          "Tareas Completadas",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(134, 134, 134, 1),
                          ),
                        ),
                        Text(
                          "$totalCompletedTasks",  // Número total de tareas completadas
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 50),  // Espacio entre los dos bloques
                    // Columna para "Tareas No Completadas"
                    Column(
                      children: [
                        Text(
                          "Tareas No Completadas",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromRGBO(134, 134, 134, 1),
                          ),
                        ),
                        Text(
                          "$totalIncompleteTasks",  // Número total de tareas no completadas
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Gráfico de tareas completadas y no completadas (Gráfico de línea)
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
                            // Días de la semana
                            switch (value.toInt()) {
                              case 1:
                                return const Text('Lun');
                              case 2:
                                return const Text('Mar');
                              case 3:
                                return const Text('Mié');
                              case 4:
                                return const Text('Jue');
                              case 5:
                                return const Text('Vie');
                              case 6:
                                return const Text('Sáb');
                              case 7:
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
                      // Línea de tareas completadas (azul)
                      LineChartBarData(
                        spots: completedTasksData,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                      ),
                      // Línea de tareas no completadas (rojo)
                      LineChartBarData(
                        spots: incompleteTasksData,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    minY: _minY,  // Establece el límite inferior del eje Y
                    maxY: _maxY, // Establece el límite superior del eje Y
                    minX: 1,  // Establecer el inicio del eje X desde el índice 1 (Lunes)
                    maxX: 7,  // Limitar el gráfico a Domingo (índice 7)
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Texto con el mensaje dependiendo de las tareas no completadas
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  mensaje,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
