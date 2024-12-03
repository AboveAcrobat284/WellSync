import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:proyecto_integrador/screens/login_user_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solicitar permisos para notificaciones (Android 13+)
  await requestNotificationPermission();

  // Inicializar Flutter Local Notifications
  initializeNotifications();

  // Inicializar WorkManager antes de que la app arranque
  Workmanager().initialize(callbackDispatcher);

  // Enviar las 3 notificaciones al iniciar la app
  sendNotification(
    'Recordatorio',
    'No olvides cumplir tus tareas del día de hoy para mantenerte productivo y no perder tu racha🔥💪',
    notificationId: 1,
  );
  sendNotification(
    'Recordatorio',
    'No olvides registrar tus horas de sueño para mejorar tus estadísticas predictivas 😴📊',
    notificationId: 2,
  );
  sendNotification(
    'Recordatorio',
    'No olvides registrar cómo te sientes el día de hoy para mejorar tus estadísticas predictivas🫀📊',
    notificationId: 3,
  );

  // Programar tareas periódicas con WorkManager
  await Workmanager().registerPeriodicTask(
    'send_notification_task_1',
    'task_send_notification_1',
    frequency: const Duration(hours: 3), // Cada 3 horas
  );

  await Workmanager().registerPeriodicTask(
    'send_notification_task_2',
    'task_send_notification_2',
    frequency: const Duration(hours: 20), // Cada 20 horas
  );

  await Workmanager().registerPeriodicTask(
    'send_notification_task_3',
    'task_send_notification_3',
    frequency: const Duration(hours: 5), // Cada 5 horas
  );

  runApp(const MyApp());
}

// Inicializar Flutter Local Notifications
void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Ícono predeterminado

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Función de WorkManager para tareas periódicas
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Tarea ejecutada: $task");
    if (task == 'task_send_notification_1') {
      sendNotification(
        'Recordatorio',
        'No olvides cumplir tus tareas del día de hoy para mantenerte productivo y no perder tu racha🔥💪',
        notificationId: 1,
      );
    } else if (task == 'task_send_notification_2') {
      sendNotification(
        'Recordatorio',
        'No olvides registrar tus horas de sueño para mejorar tus estadísticas predictivas 😴📊',
        notificationId: 2,
      );
    } else if (task == 'task_send_notification_3') {
      sendNotification(
        'Recordatorio',
        'No olvides registrar cómo te sientes el día de hoy para mejorar tus estadísticas predictivas🫀📊',
        notificationId: 3,
      );
    }
    return Future.value(true);
  });
}

// Solicitar permisos de notificación
Future<void> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print("Permiso de notificación concedido");
  } else {
    print("Permiso de notificación denegado");
  }
}

// Enviar notificaciones
void sendNotification(String title, String body, {required int notificationId}) async {
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'task_channel', // ID del canal
    'Task Notifications', // Nombre del canal
    channelDescription: 'Canal utilizado para notificaciones de tareas.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    timeoutAfter: 60000,
    styleInformation: BigTextStyleInformation(body),
  );

  NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformDetails,
    payload: 'task',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ovalScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _logoMoveUpAnimation;
  late Animation<Offset> _logoMoveDownAnimation;
  late Animation<Offset> _logoMoveLeftAnimation;
  late Animation<double> _welcomeTextOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _ovalScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.4, curve: Curves.easeIn)),
    );

    _logoMoveUpAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.3)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.4, curve: Curves.easeOut)),
    );

    _logoMoveDownAnimation = Tween<Offset>(begin: const Offset(0.35, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.5, curve: Curves.easeIn)),
    );

    _logoMoveLeftAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.1, 0)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.6, curve: Curves.easeInOut)),
    );

    _welcomeTextOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.8, curve: Curves.easeIn)),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginUserScreen()),
        );
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Transform.scale(
                      scale: _ovalScaleAnimation.value,
                      child: Image.asset(
                        'assets/Ovalo.png',
                        width: 150,
                        height: 80,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: SlideTransition(
                      position: _logoMoveUpAnimation,
                      child: SlideTransition(
                        position: _logoMoveDownAnimation,
                        child: SlideTransition(
                          position: _logoMoveLeftAnimation,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: _logoOpacityAnimation.value,
                                child: Image.asset(
                                  'assets/Logo1.png',
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Opacity(
                                opacity: _welcomeTextOpacityAnimation.value,
                                child: const Text(
                                  'BIENVENIDOS',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
