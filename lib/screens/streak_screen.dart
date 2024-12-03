import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'shop_screen.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  String? userUuid;
  String? leadUuid;

  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late DateTime _firstDayOfCurrentWeek;
  late DateTime _lastDayOfCurrentWeek;

  @override
  void initState() {
    super.initState();
    _loadUuids();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    // Calcular el primer y último día de la semana actual
    _firstDayOfCurrentWeek = _getFirstDayOfCurrentWeek(DateTime.now());
    _lastDayOfCurrentWeek = _firstDayOfCurrentWeek.add(Duration(days: 6));
  }

  // Método para cargar los uuids desde SharedPreferences
  Future<void> _loadUuids() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userUuid = prefs.getString('userUuid');
      leadUuid = prefs.getString('leadUuid');
    });
  }

  // Obtener el primer día de la semana (lunes)
  DateTime _getFirstDayOfCurrentWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1)); // Lunes de la semana actual
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(183, 84, 233, 173),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/coins.png',
                      width: 20,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Fondo blanco para toda la vista
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen de fuego (circular, similar a la de la foto)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/FireHome.png',  // Asegúrate de tener esta imagen en assets
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Número (el streak actual)
              const Text(
                '0',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 0), // Espacio adicional

              // Calendario de la semana actual (más pequeño)
              GestureDetector(
                onTap: () {
                  // Mostrar calendario completo en un modal
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return TableCalendar(
                        firstDay: DateTime.utc(2020, 01, 01),
                        lastDay: DateTime.utc(2025, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: const Color.fromARGB(183, 84, 233, 173),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(color: Colors.red),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          formatButtonVisible: false,
                          leftChevronIcon: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          rightChevronIcon: Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: Colors.black),
                          weekendStyle: TextStyle(color: Colors.black),
                        ),
                      );
                    },
                  );
                },
                child: TableCalendar(
                  firstDay: _firstDayOfCurrentWeek,
                  lastDay: _lastDayOfCurrentWeek,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color.fromARGB(183, 84, 233, 173),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.red),
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                    rightChevronIcon: Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.black),
                    weekendStyle: TextStyle(color: Colors.black),
                  ),
                  calendarBuilders: CalendarBuilders(
                    selectedBuilder: (context, date, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, date, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(183, 84, 233, 173),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Espacio adicional para agregar más widgets abajo del calendario
              const SizedBox(height: 10),
              // Contenedor con fondo blanco y borde azul con el texto y la imagen
              Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
      color: Color.fromRGBO(55, 122, 255, 1), // Borde azul
      width: 2,
    ),
  ),
            child: Row(
              children: [
                // Contenedor para la imagen y el número debajo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Imagen a la izquierda
                    Image.asset(
                      'assets/FireBlue.png', // Imagen pequeña
                      width: 40, // Tamaño reducido para evitar desbordar
                      height: 40,
                    ),
                    const SizedBox(height: 5), // Espacio entre la imagen y el número
                    // Número debajo de la imagen
                    const Text(
                      '2', // Número debajo de la imagen
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Texto al lado de la imagen
                const Expanded(
                  child: Text(
                    "¡No te preocupes! FireBlue te ayudará a recuperar tu racha y seguir avanzando.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          )
            ],
          ),
        ),
      ),
    );
  }
}
