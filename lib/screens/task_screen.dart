import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:proyecto_integrador/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'tasks_graphic_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  late stt.SpeechToText _speech;
  bool isListening = false;
  bool isHabitSelected = false;
  bool isTemporarySelected = false;
  String priority = "";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _tasks = [];
  String? _userUuid;
  final ScrollController _scrollController = ScrollController();
  Map<String, List<Map<String, dynamic>>> pastTasks = {};
  List<Map<String, dynamic>> todayTasks = [];
  Map<String, List<Map<String, dynamic>>> futureTasks = {};

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
    _loadUserUuid();
    _fetchTasks(); // Obtener tareas y clasificarlas automáticamente
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onError: (error) => debugPrint("Error de reconocimiento de voz: $error"),
    );

    if (available) {
      _speech.listen(onResult: (result) {
        setState(() {
          _taskController.text = result.recognizedWords;
        });
      });
    }
  }

  Future<void> _loadUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    _userUuid = prefs.getString('userUuid');
    if (_userUuid != null) {
      await _fetchTasks();
      _scrollToToday();
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(Uri.parse(
          'https://0dqw4sfw-3003.usw3.devtunnels.ms/api/v1/task/get'));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> allTasks =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          // Clasificar tareas por pasado, hoy y futuro
          pastTasks = _groupTasksByDate(allTasks
              .where((task) =>
                  DateTime.parse(task['date']).isBefore(today) &&
                  task['userUuid'] == _userUuid)
              .toList());
          todayTasks = allTasks
              .where((task) =>
                  DateTime.parse(task['date']).isAtSameMomentAs(today) &&
                  task['userUuid'] == _userUuid)
              .toList();
          futureTasks = _groupTasksByDate(allTasks
              .where((task) =>
                  DateTime.parse(task['date']).isAfter(today) &&
                  task['userUuid'] == _userUuid)
              .toList());
        });

        _scrollToToday(); // Posicionar el scroll en "Hoy"
      }
    } catch (e) {
      debugPrint("Error al obtener tareas: $e");
    }
  }

    Map<String, List<Map<String, dynamic>>> _groupTasksByDate(
      List<Map<String, dynamic>> tasks) {
    Map<String, List<Map<String, dynamic>>> groupedTasks = {};
    for (var task in tasks) {
      String date = task['date'];
      if (!groupedTasks.containsKey(date)) {
        groupedTasks[date] = [];
      }
      groupedTasks[date]!.add(task);
    }
    return groupedTasks;
  }

    void _scrollToToday() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final offset = _getTodayOffset();
        _scrollController.jumpTo(offset);
      });
    }
  }

    double _getTodayOffset() {
    // Calcular altura de las tareas pasadas para centrar el scroll en "Hoy"
    final pastHeight = pastTasks.values.fold<int>(
        0, (previousValue, tasks) => previousValue + (tasks.length * 100));
    return pastHeight.toDouble();
  }

  Future<void> _submitTask(String taskName) async {
    if (_userUuid == null) return;

    if (taskName.isEmpty || priority.isEmpty || selectedDate == null || selectedTime == null) {
      _showErrorDialog("Todos los campos deben ser rellenados.");
      return;
    }

    try {
      String date =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      String time =
          "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('https://0dqw4sfw-3003.usw3.devtunnels.ms/api/v1/task/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userUuid': _userUuid,
          'type': isHabitSelected ? 'Hábito' : 'Temporal',
          'priority': priority,
          'date': date,
          'time': time,
          'taskName': taskName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Tarea enviada con éxito");
        await _fetchTasks();
        _scrollToToday();
      } else {
        debugPrint("Error al enviar la tarea: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al enviar la tarea: $e");
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
        return StatefulBuilder(
          builder: (context, setStateOverlay) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: _removeOverlay,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
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
                      height: MediaQuery.of(context).size.height * 0.6,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _taskController,
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "Escribir tarea...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isListening ? Icons.mic_off : Icons.mic,
                                  color: Colors.black,
                                ),
                                onPressed: _startListening,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tipo de tarea"),
                              Row(
                                children: [
                                  Checkbox(
                                    value: isHabitSelected,
                                    onChanged: (value) {
                                      setStateOverlay(() {
                                        isHabitSelected = value!;
                                        isTemporarySelected = !value;
                                      });
                                    },
                                  ),
                                  const Text("Hábito"),
                                  Checkbox(
                                    value: isTemporarySelected,
                                    onChanged: (value) {
                                      setStateOverlay(() {
                                        isTemporarySelected = value!;
                                        isHabitSelected = !value;
                                      });
                                    },
                                  ),
                                  const Text("Temporal"),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Prioridad"),
                              Row(
                                children: [
                                  Checkbox(
                                    value: priority == "Baja",
                                    onChanged: (value) {
                                      setStateOverlay(() {
                                        priority = value! ? "Baja" : "";
                                      });
                                    },
                                  ),
                                  const Text("Baja"),
                                  Checkbox(
                                    value: priority == "Media",
                                    onChanged: (value) {
                                      setStateOverlay(() {
                                        priority = value! ? "Media" : "";
                                      });
                                    },
                                  ),
                                  const Text("Media"),
                                  Checkbox(
                                    value: priority == "Alta",
                                    onChanged: (value) {
                                      setStateOverlay(() {
                                        priority = value! ? "Alta" : "";
                                      });
                                    },
                                  ),
                                  const Text("Alta"),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Fecha"),
                              Row(
                                children: [
                                  Text(
                                    selectedDate != null
                                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                        : "No seleccionada",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () {
                                      _removeOverlay();
                                      _selectDate(context).then((_) {
                                        _showOverlay();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Hora"),
                              Row(
                                children: [
                                  Text(
                                    selectedTime != null
                                        ? "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                                        : "No seleccionada",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.access_time),
                                    onPressed: () {
                                      _removeOverlay();
                                      _selectTime(context).then((_) {
                                        _showOverlay();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _submitTask(_taskController.text);
                                setState(() {
                                  _taskController.clear();
                                  isHabitSelected = false;
                                  isTemporarySelected = false;
                                  priority = "";
                                  selectedDate = null;
                                  selectedTime = null;
                                });
                                _removeOverlay();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Guardar tarea",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
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
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(isLoggedIn: true),
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20), // Ajusta el valor para moverlo a la izquierda
            child: GestureDetector(
              onTap: _showOverlay,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(173, 216, 230, 1), // Color de fondo (azul claro)
                  shape: BoxShape.circle, // Forma circular
                ),
                child: const Icon(
                  Icons.add, // Icono de agregar
                  color: Colors.white, // Color del icono (blanco)
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Aseguramos que el contenido de las tareas se puede desplazar sin sobreponerse al botón
          SingleChildScrollView(
            controller: _scrollController, // Asignamos el controlador al SingleChildScrollView
            child: Column(
              children: [
                if (pastTasks.isNotEmpty) ...[
                  const Text(
                    'Tareas de fechas pasadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ..._buildGroupedTasks(pastTasks),
                ],
                if (todayTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Tareas por cumplir hoy',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ...todayTasks.map((task) => _buildTaskCard(task: task)),
                ],
                if (futureTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Tareas para los proximos días',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ..._buildGroupedTasks(futureTasks),
                ],
                const SizedBox(height: 80), // Agrega espacio adicional al final
              ],
            ),
          ),
          
          // Aquí es donde agregamos el botón al pie de la página
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Redirige a la pantalla de estadísticas de tareas
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TasksGraphicScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Color de fondo del botón
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Estadísticas de mis tareas',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildGroupedTasks(
      Map<String, List<Map<String, dynamic>>> groupedTasks) {
    List<Widget> widgets = [];
    groupedTasks.forEach((date, tasks) {
      widgets.add(
        Text(
          date,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
      widgets.addAll(tasks.map((task) => _buildTaskCard(task: task)).toList());
    });
    return widgets;
  }

  List<Widget> _buildTaskList() {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final todayTasks = _tasks.where((task) => task['date'] == today).toList();
    final otherTasks = _tasks.where((task) => task['date'] != today).toList();

    return [
      ...todayTasks.map((task) => _buildTaskCard(task: task)),
      const SizedBox(height: 16),
      ...otherTasks.map((task) => _buildTaskCard(task: task)),
    ];
  }

Widget _buildTaskCard({required Map<String, dynamic> task}) {
  return GestureDetector(
    onTap: () {
      // Solo mostrar la alerta si el estado de la tarea es "activa"
      if (task['status'] == 'activa') {
        _showCompletionAlert(task['id'], task['status']);
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 12, color: _getStatusColor(task['status'])),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task['taskName'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Hora: ${task['time']}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text("Tipo: ${task['type']}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text("Prioridad: ${task['priority']}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    ),
  );
}

void _showCompletionAlert(String taskId, String taskStatus) {
  // Solo mostrar la alerta si la tarea está activa
  if (taskStatus == 'activa') {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Borde redondeado para el AlertDialog
          ),
          title: const Text(
            "Confirmar acción",
            style: TextStyle(fontWeight: FontWeight.bold), // Título en negrita
          ),
          content: const Text("¿Deseas marcar como completada tu tarea?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar la alerta sin hacer nada
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white), // Color blanco para el texto
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Fondo rojo
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Bordes redondeados
                ),
              ),
            ),
            const SizedBox(width: 10), // Espacio entre los botones
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar la alerta
                await _updateTaskStatus(taskId); // Actualizar el estatus
              },
              child: const Text("Confirmar"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green, // Color del texto en blanco
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Bordes redondeados
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

  Future<void> _updateTaskStatus(String taskId) async {
    try {
      final response = await http.put(
        Uri.parse('https://0dqw4sfw-3003.usw3.devtunnels.ms/api/v1/task/update/$taskId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'terminada'}), // Actualizar el estatus a "terminada"
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("Tarea marcada como completada");
        await _fetchTasks(); // Actualizar la lista de tareas
      } else {
        debugPrint("Error al actualizar la tarea: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al actualizar la tarea: $e");
    }
  }


  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'terminada': // Tarea terminada
        return Colors.green;
      case 'activa': // Tarea activa
        return Colors.red;
      default: // Cualquier otro estado
        return Colors.grey;
    }
  }
}