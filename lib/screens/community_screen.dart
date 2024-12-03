import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'chat_screen.dart';
import 'home_screen.dart';
import 'graphics_screen.dart';
import 'my_profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  final String userUuid;
  final String leadUuid;

  const CommunityScreen({super.key, required this.userUuid, required this.leadUuid});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _messageController = TextEditingController();
  late stt.SpeechToText _speech;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  Timer? _updateTimer;
  String userProfilePicture = ""; // Para precargar la foto de perfil del usuario
  bool _isFirstLoad = true; // Controla si es la primera carga de mensajes

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
    _fetchMessages();
    _fetchUserProfilePicture();

    // Configura un Timer para actualizar los mensajes en tiempo real
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchMessages();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
  }

  Future<void> _requestMicrophonePermission() async {
    if (await Permission.microphone.request().isGranted) {
      debugPrint("Permiso de micrófono concedido");
    } else {
      debugPrint("Permiso de micrófono denegado");
    }
  }

  Future<void> _startListening() async {
    if (!mounted) return;

    await _requestMicrophonePermission();

    if (await Permission.microphone.isGranted) {
      bool available = await _speech.initialize(
        onError: (error) => debugPrint("Error de reconocimiento de voz: $error"),
      );

      if (available) {
        _speech.listen(onResult: (result) {
          if (mounted) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });
          }
        });
      }
    } else {
      debugPrint("Permiso de micrófono requerido para usar esta función.");
    }
  }

  Future<void> _fetchMessages() async {
    const String url = 'https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/comments/get';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            messages = data.cast<Map<String, dynamic>>();
          });

          // Solo posiciona el scroll al final en la primera carga
          if (_isFirstLoad) {
            _scrollToBottom();
            _isFirstLoad = false; // Desactiva el scroll automático
          }
        }
      } else {
        debugPrint("Error al obtener los mensajes: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al cargar mensajes: $e");
    }
  }

  Future<void> _fetchUserProfilePicture() async {
    const String url = 'https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/user/profile-picture';

    try {
      final response = await http.get(Uri.parse('$url/${widget.userUuid}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userProfilePicture = data['profilePicture'] ?? "";
        });
        // Precachea la imagen de perfil del usuario
        if (userProfilePicture.isNotEmpty) {
          precacheImage(NetworkImage(userProfilePicture), context);
        }
      } else {
        debugPrint("Error al obtener la foto de perfil: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al cargar la foto de perfil del usuario: $e");
    }
  }

  Future<void> _sendMessage(String content) async {
    const String url = 'https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/comments/create';

    final newMessage = {
      "userId": widget.userUuid,
      "content": content,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newMessage),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            messages.add({
              "id": DateTime.now().toString(),
              "userId": widget.userUuid,
              "content": content,
              "createdAt": DateTime.now().toIso8601String(),
              "firstName": "Tú",
              "lastName": "",
              "profilePicture": userProfilePicture,
            });
          });
          _messageController.clear();
          _scrollToBottom(); // Posiciona el scroll al final después de enviar un mensaje
        }
      } else {
        debugPrint("Error al enviar el mensaje: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al enviar mensaje: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "WS - Comunidad",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message["userId"] == widget.userUuid;
                  final profilePicture = message["profilePicture"] ?? "";

                  return isMine
                      ? _buildMyMessage(message["content"], profilePicture)
                      : _buildOtherMessage(
                          "${message["firstName"] ?? "Usuario"} ${message["lastName"] ?? ""}",
                          message["content"],
                          profilePicture,
                        );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _buildMessageInputField(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBarWithAnimation(
        selectedIndex: 3,
        userUuid: widget.userUuid,
        leadUuid: widget.leadUuid,
      ),
    );
  }

  Widget _buildOtherMessage(String name, String message, String profilePicture) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color.fromARGB(255, 156, 250, 233),
            backgroundImage: profilePicture.isNotEmpty
                ? NetworkImage(profilePicture)
                : null,
            child: profilePicture.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 217, 255, 248),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMessage(String message, String profilePicture) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue,
            backgroundImage: profilePicture.isNotEmpty
                ? NetworkImage(profilePicture)
                : null,
            child: profilePicture.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Escribir mensaje",
                hintStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            onPressed: _startListening,
            icon: const Icon(Icons.mic, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _sendMessage(_messageController.text);
              }
            },
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}


// Barra de navegación inferior (sin cambios)
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

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(isLoggedIn: true),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userUuid: widget.userUuid,
              leadUuid: widget.leadUuid,
            ),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GraphicsScreen(
              userUuid: widget.userUuid,
              leadUuid: widget.leadUuid,
            ),
          ),
        );
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyProfileScreen(
              userUuid: widget.userUuid,
              leadUuid: widget.leadUuid,
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
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
                30,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SmoothUShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.moveTo(0, size.height * 0);

    path.quadraticBezierTo(
      size.width * 0.2, size.height,
      size.width * 0.5, size.height,
    );

    path.quadraticBezierTo(
      size.width * 0.8, size.height,
      size.width, size.height * 0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
