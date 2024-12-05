import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'chat_screen.dart';
import 'community_screen.dart';
import 'emotions_graphic_statistics_screen.dart';
import 'graphics_screen.dart';
import 'my_profile_screen.dart';  // Para manejar la codificación JSON

class EmotionsGraphicScreen extends StatelessWidget {
  final String userUuid;
  final String leadUuid;

  const EmotionsGraphicScreen({
    super.key,
    required this.userUuid,
    required this.leadUuid,
  });

// Verificar si el usuario ya registró una emoción hoy
  Future<bool> _canRecordEmotion() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastRecordedDate = prefs.getString('lastRecordedDate');

    if (lastRecordedDate == null) {
      return true; // No se ha registrado ninguna emoción, permitir el registro
    }

    DateTime lastDate = DateTime.parse(lastRecordedDate);
    DateTime today = DateTime.now();

    // Comparar si la fecha almacenada es del día de hoy
    if (lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day) {
      return false; // Ya se registró una emoción hoy
    } else {
      return true; // Es un nuevo día, permitir el registro
    }
  }

  // Guardar la fecha y hora de la emoción registrada
  Future<void> _saveRecordedDate() async {
      final prefs = await SharedPreferences.getInstance();
      DateTime now = DateTime.now();
      prefs.setString('lastRecordedDate', now.toIso8601String());
  }

// Función para enviar la emoción a la API
Future<void> _sendEmotionToApi(String emotion) async {
  final prefs = await SharedPreferences.getInstance();
  String? userUuid = prefs.getString('userUuid');  // Obtener el userUuid almacenado

  if (userUuid == null) {
    print("No se encontró el UUID del usuario.");
    return;
  }

  // Datos que vamos a enviar
  final Map<String, dynamic> data = {
    'useruuid': userUuid,
    'emocion': emotion.toLowerCase(), // Aseguramos que la emoción esté en minúsculas
  };

  // Imprimir los datos antes de enviar
  print("Enviando datos a la API: ${jsonEncode(data)}");

  // Enviar la emoción en minúsculas y el userUuid a la API
  try {
    final response = await http.post(
      Uri.parse('https://0dqw4sfw-5000.usw3.devtunnels.ms/api/emociones'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Imprimir la respuesta en consola
      print("Respuesta de la API: ${response.body}");
    } else {
      print("Error en la API: ${response.statusCode}");
      print("Cuerpo de la respuesta: ${response.body}");
    }
  } catch (e) {
    print("Error al enviar la emoción: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Emociones",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Diagnóstico psicológico",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "¿Cómo describes tu humor el día de hoy?",
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  List<String> emojis = [
                    '😁', '😰', '😭', '😐', '😴', '😡'
                  ];
                  List<String> emotionsText = [
                    'Feliz', 'Nervioso', 'Triste', 'Neutral', 'Aburrido', 'Enojado'
                  ];

                  return ElevatedButton(
                    onPressed: () async {
                      bool canRecord = await _canRecordEmotion();
                      if (!canRecord) {
                        // Mostrar alerta si ya se registró una emoción hoy
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color.fromARGB(255, 0, 215, 186),  // Fondo del diálogo
                            title: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.white),  // Ícono de advertencia
                                SizedBox(width: 10),
                                Text('¡Alerta!', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            content: const Text(
                              'Solo puedes registrar una emoción por día.',
                              style: TextStyle(color: Colors.white),  // Texto blanco
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Guardar la fecha del registro y realizar la acción
                        await _saveRecordedDate();
                        // Enviar la emoción seleccionada a la API
                        await _sendEmotionToApi(emotionsText[index]);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadowColor: Colors.black.withOpacity(0.2),
                      elevation: 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emotionsText[index],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 0, 0, 0), // Cambiar el color del texto a blanco
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmotionsGraphicStatisticsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Estadísticas de mis emociones",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavigationBarWithAnimation(
        selectedIndex: 2,
        userUuid: userUuid,
        leadUuid: leadUuid,
      ),
    );
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
