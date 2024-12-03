import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isGmailSelected = false;
  bool _isWhatsAppSelected = false;

  void _onGmailChanged(bool? value) {
    setState(() {
      _isGmailSelected = value ?? false;
      if (_isGmailSelected) {
        _isWhatsAppSelected = false;
      }
    });
  }

  void _onWhatsAppChanged(bool? value) {
    setState(() {
      _isWhatsAppSelected = value ?? false;
      if (_isWhatsAppSelected) {
        _isGmailSelected = false;
      }
    });
  }

  Future<void> _registerUser() async {
    const String apiUrl = "https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/lead/create";
    String notificationPreference = _isGmailSelected ? "email" : "whatsapp";

    Map<String, dynamic> body = {
      "first_Name": _firstNameController.text,
      "last_Name": _lastNameController.text,
      "correo": _emailController.text,
      "phone": _phoneController.text,
      "notification_preference": notificationPreference,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showAlert(context, "Usuario creado correctamente", true);
      } else {
        _showAlert(context, "Error al crear usuario: ${response.body}", false);
      }
    } catch (e) {
      print("Error de conexión: $e");
      _showAlert(context, "Error de conexión: $e", false);
    }
  }

  void _showAlert(BuildContext context, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            isSuccess ? "Éxito" : "Error",
            style: TextStyle(color: isSuccess ? Colors.green : Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  // Redirigir al HomeScreen con la bandera fromRegister: true
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(isLoggedIn: false, fromRegister: true),
                    ),
                  );
                }
              },
              child: const Text("Aceptar", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset(
                'assets/Logo1.png',
                width: 130,
                height: 130,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8ECF4),
                        labelText: 'Nombre',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8ECF4),
                        labelText: 'Apellido',
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE8ECF4),
                  labelText: 'Correo',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE8ECF4),
                  labelText: 'Número',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¿Dónde deseas recibir las notificaciones?',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isGmailSelected,
                onChanged: _onGmailChanged,
                title: const Text('Gmail'),
                secondary: const FaIcon(FontAwesomeIcons.envelope, color: Colors.red),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _isWhatsAppSelected,
                onChanged: _onWhatsAppChanged,
                title: const Text('WhatsApp'),
                secondary: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Registrarse',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
