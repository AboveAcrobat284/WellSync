import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late stt.SpeechToText _speech;
  OverlayEntry? _overlayEntry;

  List<Map<String, dynamic>> _entries = [];
  String? _userUuid;

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
    _loadUserUuid();
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
  }

  Future<void> _loadUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    _userUuid = prefs.getString('userUuid');
    if (_userUuid != null) {
      await _fetchEntries();
      _scrollToEnd();
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onError: (error) => debugPrint("Error de reconocimiento de voz: $error"),
    );

    if (available) {
      _speech.listen(onResult: (result) {
        setState(() {
          _messageController.text = result.recognizedWords;
        });
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error al tomar foto: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen de la galería: $e");
    }
  }

  Future<void> _fetchEntries() async {
    try {
      final response = await http.get(Uri.parse(
          'https://0dqw4sfw-3003.usw3.devtunnels.ms/api/v1/diary/get'));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> allEntries =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          _entries = allEntries
              .where((entry) => entry['userUuid'] == _userUuid)
              .toList()
            ..sort((a, b) {
              DateTime dateA = DateTime.parse(a['date'] + ' ' + a['time']);
              DateTime dateB = DateTime.parse(b['date'] + ' ' + b['time']);
              return dateA.compareTo(dateB);
            });
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las entradas: $e");
    }
  }

  Future<void> _submitEntry(String comment, File? image) async {
    if (_userUuid == null) return;

    if (comment.isEmpty || image == null) {
      _showErrorDialog("Todos los campos deben ser rellenados.");
      return;
    }

    try {
      final now = DateTime.now();
      String date =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      String time =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://0dqw4sfw-3003.usw3.devtunnels.ms/api/v1/diary/create'),
      );

      request.fields['userUuid'] = _userUuid!;
      request.fields['comment'] = comment;
      request.fields['date'] = date;
      request.fields['time'] = time;

      // ignore: unnecessary_null_comparison
      if (image != null) {
        request.files.add(
            await http.MultipartFile.fromPath('image', image.path));
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Entrada enviada con éxito");
        // Actualizar la vista inmediatamente después del envío exitoso
        await _fetchEntries();
        _scrollToEnd();
      } else {
        debugPrint("Error al enviar la entrada: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al enviar la entrada: $e");
    }
  }


  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _removeOverlay,
              child: Container(
                color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height / 2,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: "Escribir comentario...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImage != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        const Text("No hay imagen seleccionada",
                            style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera, color: Colors.green),
                            onPressed: () async {
                              await _takePhoto();
                              _removeOverlay();
                              _showOverlay();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.blue),
                            onPressed: () async {
                              await _pickFromGallery();
                              _removeOverlay();
                              _showOverlay();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic, color: Colors.black),
                            onPressed: _startListening,
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: () async {
                              await _submitEntry(_messageController.text, _selectedImage);
                              _removeOverlay();
                              setState(() {
                                _messageController.clear();
                                _selectedImage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: const BackButton(color: Color.fromARGB(255, 0, 0, 0)),
        title: const Text(
          "Mi diario",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return _buildDiaryEntry(
                    date: entry['date'] ?? '',
                    time: entry['time'] ?? '',
                    comment: entry['comment'] ?? '',
                    imageUrl: entry['image'] ?? '',
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOverlay,
        backgroundColor: const Color(0xFFE5B2FF),
        shape: const CircleBorder(), // Asegura que sea circular
        child: const Icon(
          Icons.add,
          size: 36.0, // Tamaño personalizado
          color: Color.fromARGB(255, 255, 255, 255), // Color personalizado
        ),
      ),
    );
  }

  Widget _buildDiaryEntry({
    required String date,
    required String time,
    required String comment,
    required String imageUrl,
  }) {
    final now = DateTime.now();
    final isToday = date == "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        isToday ? 'Hoy' : date,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isToday
              ? const Color.fromARGB(144, 3, 170, 45)
              : const Color.fromARGB(169, 249, 67, 67), // Cambia el color dinámicamente
        ),
      ),
      const SizedBox(height: 8.0), // Espacio debajo del texto de la fecha
      Text(time, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      const SizedBox(height: 8.0), // Espacio debajo del texto del tiempo
      if (imageUrl.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: double.infinity, // Ancho máximo del contenedor
              maxHeight: 300, // Altura máxima del contenedor
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover, // Ajusta la imagen al tamaño del contenedor
            ),
          ),
        ),
      const SizedBox(height: 8.0), // Espacio debajo de la imagen
      Text(
        comment,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: Color.fromRGBO(43, 47, 52, 0.864), // Código hexadecimal del color
        ),
      ),
      const SizedBox(height: 16.0), // Espacio debajo del texto del comentario
      const Divider(), // Línea divisoria
      const SizedBox(height: 35.0), // Espacio debajo de toda la columna
    ],
  );
  }
}
