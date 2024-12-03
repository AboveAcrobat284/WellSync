import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'create_new_password_screen.dart';

class VerificationFpScreen extends StatefulWidget {
  const VerificationFpScreen({super.key});

  @override
  State<VerificationFpScreen> createState() => _VerificationFpScreenState();
}

class _VerificationFpScreenState extends State<VerificationFpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  String? _userUuid;

  Future<void> _verifyCode() async {
    String token = _controllers.map((controller) => controller.text).join();

    if (token.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete el código de verificación.')),
      );
      return;
    }

    try {
      const String apiUrl = 'https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/reset/validate-token';
      Map<String, dynamic> requestBody = {"token": token};

      print("Enviando token a la API: $token");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("Código de respuesta: ${response.statusCode}");
      print("Cuerpo de la respuesta: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userUuid = data['UserUuid'];

        if (_userUuid != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userUuid', _userUuid!);

          _showAlert(context, "Código de validación enviado correctamente", true);
        } else {
          print("El UUID no está presente en la respuesta de la API.");
        }
      } else {
        _showAlert(context, "Error al enviar código de validación: ${response.body}", false);
      }
    } catch (e) {
      print("Error durante la conexión: $e");
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
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateNewPasswordScreen(userUuid: _userUuid!),
                    ),
                  );
                }
              },
              child: const Text(
                "Aceptar",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
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
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Verificación',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el código de verificación para poder restablecer tu contraseña',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  height: 80,
                  child: TextField(
                    controller: _controllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(0),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(118, 215, 196, 1),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(118, 215, 196, 1),
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 24),
                    onChanged: (value) {
                      if (value.length == 1) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Verificar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
