import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';

class SleepGraphicScreen extends StatefulWidget {
  final String userUuid;
  final String leadUuid;

  const SleepGraphicScreen({super.key, required this.userUuid, required this.leadUuid});

  @override
  _SleepGraphicScreenState createState() => _SleepGraphicScreenState();
}

class _SleepGraphicScreenState extends State<SleepGraphicScreen> {
  String _emoji = "😴"; // Emoji inicial
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  int _sleepTimeInSeconds = 0; // Para medir el tiempo de sueño en segundos
  bool _isTimerRunning = false; // Controla si el cronómetro está corriendo
  late DateTime _startTime;
  Timer? _timer; // Cambiado a un Timer opcional
  bool _notificationSent = false; // Flag para controlar la notificación de inicio

  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Inicializar las notificaciones
  }

  // Inicializar las notificaciones
  void _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); // Inicializa el plugin

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Cambia el ícono según tu aplicación

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings); // Asegúrate de que el plugin esté inicializado
  }

  // Función para mostrar la notificación
  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sleep_channel', // Canal
      'Sleep Timer', // Nombre del canal
      channelDescription: 'Notifications for sleep timer',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      title, // Título
      body, // Cuerpo
      notificationDetails,
    );
  }

  // Función para iniciar el cronómetro
  void _startTimer() {
    setState(() {
      _emoji = "😴"; // Cambiar el emoji al iniciar el contador
      _isTimerRunning = true;
      _startTime = DateTime.now(); // Guardar la hora de inicio
    });

    // Enviar notificación solo una vez cuando inicie el cronómetro
    if (!_notificationSent) {
      _showNotification('Contador de Sueño', 'El contador de sueño ha comenzado.');
      _notificationSent = true; // Marcar como enviada la notificación
    }

    // Iniciar el cronómetro que se actualiza cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerRunning) {
        _timer?.cancel(); // Detener el cronómetro cuando se detenga
      } else {
        setState(() {
          _sleepTimeInSeconds = DateTime.now().difference(_startTime).inSeconds;
        });
      }
    });
  }

  // Función para detener el cronómetro
  void _stopTimer() {
    setState(() {
      _emoji = "😁"; // Cambiar el emoji al detener el contador
      _isTimerRunning = false;
    });

    // Enviar notificación cuando se detiene el cronómetro
    _showNotification(
      'Contador de Sueño Detenido',
      'El contador de sueño se ha detenido. El tiempo total fue de ${_formatTime(_sleepTimeInSeconds)}.',
    );

    // Reiniciar el contador a 0
    setState(() {
      _sleepTimeInSeconds = 0;
      _notificationSent = false; // Permitir la notificación al reiniciar
    });
  }

  // Convertir el tiempo en segundos a formato de horas, minutos y segundos
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el Timer solo si existe
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView( // Aquí envolvemos todo en un SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Aquí puede iniciar el conteo de sueño diario para poder así llevar un conteo de tus horas de sueño diariamente.",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromRGBO(145, 143, 167, 1),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () {
                    print("Emoji tocado");
                  },
                  child: Text(
                    _emoji,
                    style: const TextStyle(
                      fontSize: 100,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  _formatTime(_sleepTimeInSeconds), // Mostrar el cronómetro en formato HH:MM:SS
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isTimerRunning ? null : _startTimer,
                    label: const Text(
                      "Iniciar contador de sueño",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(109, 33, 243, 65),
                      minimumSize: Size(155, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _isTimerRunning ? _stopTimer : null,
                    label: const Text(
                      "Parar contador de sueño",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(148, 243, 33, 33),
                      minimumSize: Size(150, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Este diagnostico está realizado con el fin de observar el tiempo que duermes semanalmente.",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromRGBO(145, 143, 167, 1),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Estadísticas semanales",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 0),
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
                      // Línea de las horas de sueño reales
                      LineChartBarData(
                        spots: _createSleepData(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                      ),
                      // Línea de horas de sueño predichas
                      LineChartBarData(
                        spots: _createPredictedSleepData(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Datos de ejemplo para el gráfico de horas de sueño reales
  List<FlSpot> _createSleepData() {
    return [
      FlSpot(0, 8),  // Lunes
      FlSpot(1, 7),  // Martes
      FlSpot(2, 6),  // Miércoles
      FlSpot(3, 8),  // Jueves
      FlSpot(4, 7),  // Viernes
      FlSpot(5, 8),  // Sábado
      FlSpot(6, 6),  // Domingo
    ];
  }

  // Datos de ejemplo para el gráfico de horas de sueño predichas
  List<FlSpot> _createPredictedSleepData() {
    return [
      FlSpot(0, 7),  // Lunes
      FlSpot(1, 7),  // Martes
      FlSpot(2, 7),  // Miércoles
      FlSpot(3, 7),  // Jueves
      FlSpot(4, 7),  // Viernes
      FlSpot(5, 7),  // Sábado
      FlSpot(6, 7),  // Domingo
    ];
  }
}
