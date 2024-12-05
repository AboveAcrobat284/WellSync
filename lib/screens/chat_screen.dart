import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'community_screen.dart';
import 'graphics_screen.dart';
import 'home_screen.dart';
import 'my_profile_screen.dart';

const String apiKey = "AIzaSyAoudGpp--Mr5C_0nTpyuWU7lk9Lx_iGxU";

class ChatScreen extends StatefulWidget {
  final String userUuid;
  final String leadUuid;

  const ChatScreen({Key? key, required this.userUuid, required this.leadUuid}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool _isListening = false;
  bool _isConnected = true;
  String _speechText = '';
  final String _selectedLanguage = "es-MX";
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeService() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _chatSession = _model.startChat();

    await _requestMicrophonePermission();
    await _checkInternetConnection();
    await _loadMessages();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://google.com'));
      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
        });
      } else {
        setState(() {
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            _stopListening();
          }
        },
        onError: (val) => print('Error: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _speechText = val.recognizedWords;
              _controller.text = _speechText;
            });
          },
          localeId: _selectedLanguage,
        );
      }
    } else {
      print("Permisos de micrófono denegados");
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

Future<void> _sendMessage() async {
  await _checkInternetConnection();

  if (!_isConnected) {
    setState(() {
      _messages.add(ChatMessage(
          text: "No se puede enviar el mensaje. Conéctate a Internet.", isUser: false));
    });
    return;
  }

  if (_controller.text.isNotEmpty) {
    String userMessage = _controller.text;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: "Corrigiendo y analizando...", isUser: false));
    });

    try {
      // 1. Corregir el mensaje y filtrar groserías
      final correctedMessage = await _correctAndFilterMessage(userMessage);

      // Actualizar la burbuja azul con el mensaje corregido
      setState(() {
        _messages.removeLast(); // Eliminar "Corrigiendo y analizando..."
        _messages.add(ChatMessage(text: correctedMessage, isUser: true)); // Solo el mensaje corregido
      });

      // 2. Obtener la respuesta del bot usando el mensaje corregido
      final response = await _chatSession.sendMessage(
        Content.text(correctedMessage), // Usar mensaje corregido
      );
      final botResponse = response.text ?? "No se recibió respuesta.";

      // Mostrar la respuesta del bot en un globo verde
      setState(() {
        _messages.add(ChatMessage(text: botResponse, isUser: false));
      });

    } catch (e) {
      setState(() {
        _messages.removeLast(); // Eliminar "Corrigiendo y analizando..."
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
      });
    }
  }
}



// Método para corregir y filtrar mensaje con Gemini Pro
Future<String> _correctAndFilterMessage(String message) async {
  try {
    // Usamos el modelo `GenerativeModel` para enviar el prompt de corrección
    final response = await _chatSession.sendMessage(
      Content.text(
        "Arregla los errores de ortografía de este mensaje y marca las palabras obscenas con asteriscos: $message",
      ),
    );

    // Devolver la respuesta corregida
    return response.text ?? message;
  } catch (e) {
    print('Error al corregir el mensaje: $e');
    return message; // Devuelve el mensaje original en caso de error
  }
}

  String _getContext() {
    int numberOfMessages = _messages.length < 10 ? _messages.length : 10;
    return _messages
        .take(numberOfMessages)
        .map((msg) => "${msg.isUser ? 'Usuario' : 'Bot'}: ${msg.text}")
        .join("\n");
  }

  Future<void> _speak(String text) async {
    // Configura el idioma para la síntesis de voz
    await _flutterTts.setLanguage("es-MX");
    await _flutterTts.speak(text);
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> messagesToSave = _messages
        .take(100)
        .map((msg) => "${msg.isUser ? 'user:' : 'bot:'}${msg.text}")
        .toList();
    await prefs.setStringList('chatMessages', messagesToSave);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedMessages = prefs.getStringList('chatMessages');

    if (savedMessages != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(savedMessages.map((msg) {
          bool isUser = msg.startsWith('user:');
          String text = msg.replaceFirst(isUser ? 'user:' : 'bot:', '');
          return ChatMessage(text: text, isUser: isUser);
        }).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUserMessage = _messages[index].isUser;
                return Row(
                  mainAxisAlignment: isUserMessage
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isUserMessage)
                      const CircleAvatar(
                        backgroundColor: Colors.greenAccent,
                        child: Icon(Icons.smart_toy, color: Colors.white),
                      ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isUserMessage ? Colors.blueAccent : Colors.greenAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _messages[index].text,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (isUserMessage)
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  color: Colors.blueAccent,
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.greenAccent,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavigationBarWithAnimation(
        selectedIndex: 1,
        userUuid: widget.userUuid,
        leadUuid: widget.leadUuid,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              userUuid: widget.userUuid,
              leadUuid: widget.leadUuid,
            ),
          ),
        );
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
