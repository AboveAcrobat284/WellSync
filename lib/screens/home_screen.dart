import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'inactive_token_screen.dart';
import 'my_profile_screen.dart';
import 'graphics_screen.dart';
import 'community_screen.dart';
import 'chat_screen.dart'; // Importamos ChatScreen
import 'streak_screen.dart';
import 'task_screen.dart'; // Importamos TaskScreen
import 'diary_screen.dart'; // Importamos DiaryScreen

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn; // Indica si el usuario ha iniciado sesión
  final bool fromRegister; // Indica si el usuario viene desde RegisterScreen

  const HomeScreen({super.key, required this.isLoggedIn, this.fromRegister = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userUuid;
  String? leadUuid;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadUUIDs();
    }
  }

  void _loadUUIDs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userUuid = prefs.getString('userUuid');
      leadUuid = prefs.getString('leadUuid');
    });
  }

  Future<String> _fetchUserName() async {
    if (leadUuid == null) return "Usuario";

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

  void _redirectToInactiveScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InactiveTokenScreen()),
    );
  }

  void _handleInteraction(void Function()? action) {
    if (widget.fromRegister) {
      _redirectToInactiveScreen();
    } else if (action != null) {
      action();
    }
  }

  void _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://sites.google.com/ids.upchiapas.edu.mx/politica-privacidad-wellsync/inicio');
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'No se pudo abrir el enlace $url';
      }
    } catch (e) {
      debugPrint('Error al abrir el enlace: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el enlace: $e')),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: GestureDetector(
      onTap: widget.fromRegister ? _redirectToInactiveScreen : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _handleInteraction(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyProfileScreen(
                          userUuid: userUuid ?? 'UUID no disponible',
                          leadUuid: leadUuid ?? 'UUID no disponible',
                        ),
                      ),
                    );
                  }),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black,
                        child: const Icon(Icons.person_outline, color: Colors.white),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: widget.fromRegister ? Colors.red : Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _fetchUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text("Error al cargar el nombre");
                } else {
                  final userName = snapshot.data ?? "Usuario";
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(244, 250, 180, 1),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hola, $userName",
                              style: const TextStyle(
                                  fontSize: 22,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tu tienes el control de tu cuerpo",
                              style: TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ],
                        ),
                        // Agregamos GestureDetector para redirigir a StreakScreen
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StreakScreen(), // Aquí se redirige a StreakScreen
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/FireHome.png',
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(height: 0),
                              const Text(
                                "0",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 0),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.8,
                ),
                children: [
                  _buildImageButton(
                    'assets/ChatBot.png',
                    onTap: () => _handleInteraction(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userUuid: userUuid ?? 'UUID no disponible',
                            leadUuid: leadUuid ?? 'UUID no disponible',
                          ),
                        ),
                      );
                    }),
                  ),
                  _buildImageButton(
                    'assets/GraficasHome.png',
                    onTap: () => _handleInteraction(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraphicsScreen(
                            userUuid: userUuid!,
                            leadUuid: leadUuid!,
                          ),
                        ),
                      );
                    }),
                  ),
                  _buildImageButton(
                    'assets/ComunidadHome.png',
                    onTap: () => _handleInteraction(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityScreen(
                            userUuid: userUuid!,
                            leadUuid: leadUuid!,
                          ),
                        ),
                      );
                    }),
                  ),
                  _buildImageButton(
                    'assets/TareasHome.png',
                    onTap: () => _handleInteraction(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TaskScreen()),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildFooterButton(
                  "Diario",
                  onTap: () => _handleInteraction(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiaryScreen()),
                    );
                  }),
                ),
                _buildFooterButton(
                  "Acerca de",
                  underline: true,
                  onTap: () => _handleInteraction(() => _openPrivacyPolicy()),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildImageButton(String assetPath, {void Function()? onTap}) {
    return GestureDetector(
      onTap: () => _handleInteraction(onTap),
      child: Center(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFooterButton(String label, {bool underline = false, void Function()? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleInteraction(onTap),
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(244, 250, 180, 1),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 7),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: underline ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
