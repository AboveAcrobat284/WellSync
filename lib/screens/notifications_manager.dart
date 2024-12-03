import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart'; // Importar para permisos

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Función para inicializar las notificaciones
Future<void> initNotifications() async {
  // Solicitar permiso para notificaciones
  await requestNotificationPermission();

  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Crear el canal de notificaciones solo si no existe
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'task_channel', // ID del canal
    'Task Notifications', // Nombre del canal
    description: 'Este canal es utilizado para las notificaciones de tareas.',
    importance: Importance.high,  // Asegura que las notificaciones son de alta importancia
  );

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// Función para solicitar permisos de notificación (Android 13+)
Future<void> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print("Permiso de notificación concedido");
  } else {
    print("Permiso de notificación denegado");
  }
}

// Función para enviar notificación
void sendNotification(String title, String body) async {
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'task_channel', // ID del canal
    'Task Notifications', // Nombre del canal
    channelDescription: 'Este canal es utilizado para las notificaciones de tareas.',
    importance: Importance.max,  // Asegura que la notificación sea de alta prioridad
    priority: Priority.high,     // Prioridad alta para que se muestre al instante
    playSound: true,             // Sonido de la notificación
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Vibración
    timeoutAfter: 60000,         // Se mantendrá 1 minuto
  );
  NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0, title, body, platformDetails,
    payload: 'task', // Esto se puede usar para agregar más datos
  );
}
