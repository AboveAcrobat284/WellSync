import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'community_screen.dart';
import 'emotions_graphic_screen.dart';
import 'my_profile_screen.dart';
import 'sleep_graphic_screen.dart';
import 'steps_graphic_screen.dart';

class GraphicsScreen extends StatelessWidget {
  final String userUuid;
  final String leadUuid;

  const GraphicsScreen({super.key, required this.userUuid, required this.leadUuid});

  Future<String> _fetchUserName() async {
    final response = await http.get(
      Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/lead/get/$leadUuid'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['first_Name'] ?? "Usuario";
    } else {
      throw Exception("Error al obtener el nombre del usuario");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color.fromARGB(255, 0, 0, 0)),
        title: FutureBuilder<String>(
          future: _fetchUserName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text("Hola, Usuario");
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person_outline, color: Colors.white),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Hola, ${snapshot.data}!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 27), // Espacio extra entre la cabecera y las tarjetas
            Expanded(
              child: ListView(
                children: [
                  _buildCard(
                    context: context,
                    title: "Diagnostico",
                    assetPath: "assets/Emociones.png",
                    backgroundColor: const Color.fromARGB(255, 173, 216, 230),
                    reverse: false,
                    onTap: () {
                      // Redirige a la vista de Diagnóstico
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmotionsGraphicScreen(userUuid: userUuid, leadUuid: leadUuid), // Cambia por tu vista
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCard(
                    context: context,
                    title: "Pasos",
                    assetPath: "assets/Pasos.png",
                    backgroundColor: const Color.fromARGB(255, 240, 230, 140),
                    reverse: true,
                    onTap: () {
                      // Redirige a la vista de Pasos
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StepsGraphicScreen(userUuid: userUuid, leadUuid: leadUuid), // Cambia por tu vista
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCard(
                    context: context,
                    title: "Sueño",
                    assetPath: "assets/Sueño.png",
                    backgroundColor: const Color.fromARGB(255, 173, 216, 230),
                    reverse: false,
                    onTap: () {
                      // Redirige a la vista de Sueño
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SleepGraphicScreen(userUuid: userUuid, leadUuid: leadUuid), // Cambia por tu vista
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBarWithAnimation(
        selectedIndex: 2,
        userUuid: userUuid,
        leadUuid: leadUuid,
      ),
    );
  }

  // Actualización de _buildCard para recibir una función onTap
  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String assetPath,
    required Color backgroundColor,
    required bool reverse,
    required VoidCallback onTap, // Añadido el callback
  }) {
    return GestureDetector(
      onTap: onTap, // Al hacer tap se redirige
      child: Container(
        height: MediaQuery.of(context).size.height * 0.24, // Altura aumentada
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: reverse
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, // Aumentamos el tamaño de la fuente
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Image.asset(
                    assetPath,
                    width: MediaQuery.of(context).size.width * 0.4, // Imagen más grande
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                ]
              : [
                  Image.asset(
                    assetPath,
                    width: MediaQuery.of(context).size.width * 0.4, // Imagen más grande
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, // Aumentamos el tamaño de la fuente
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
        ),
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
