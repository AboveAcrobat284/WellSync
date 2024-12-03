import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'token_validation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
  final String correo = _emailController.text.trim();
  final String password = _passwordController.text.trim();
  final String confirmPassword = _confirmPasswordController.text.trim();
  final String notificationPreference = _isGmailSelected ? "email" : _isWhatsAppSelected ? "whatsapp" : "";

  if (correo.isEmpty || password.isEmpty || confirmPassword.isEmpty || notificationPreference.isEmpty) {
    _showAlert(context, "Por favor, complete todos los campos.", false);
    return;
  }

  const String apiUrl = "https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/users/create";
  Map<String, dynamic> body = {
    "correo": correo,
    "password": password,
    "confirmPassword": confirmPassword,
    "notificationPreference": notificationPreference,
  };

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      // Imprimir el contenido de responseData para depurar
      print("Respuesta de la API: $responseData");

      // Accede al uuid dentro del objeto "user"
        if (responseData.containsKey("user") && responseData["user"].containsKey("uuid")) {
          String userUuid = responseData["user"]["uuid"];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userUuid', userUuid);

          _showAlert(context, "Registro exitoso", true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TokenValidationScreen(userUuid: userUuid),
            ),
          );
        } else {
          // Muestra un error si no se encuentra la clave userUuid en la respuesta
          _showAlert(context, "Error: UUID del usuario no encontrado en la respuesta.", false);
        }
      } else {
        _showAlert(context, "Error al registrar usuario: ${response.body}", false);
      }
    } catch (e) {
      _showAlert(context, "Error de conexión: $e", false);
    }
  }

  // Método para mostrar alertas (incluido en la clase)
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
              },
              child: Text("Aceptar", style: TextStyle(color: Colors.black)),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/Logo1.png',
                width: 130,
                height: 130,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE8ECF4),
                  labelText: 'Ingresa tu correo',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE8ECF4),
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE8ECF4),
                  labelText: 'Confirmar contraseña',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
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
                  'Registrar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
