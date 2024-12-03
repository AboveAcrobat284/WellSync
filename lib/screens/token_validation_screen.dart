import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'token_activated_screen.dart';

class TokenValidationScreen extends StatelessWidget {
  final String userUuid;

  TokenValidationScreen({super.key, required this.userUuid});

  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();

  Future<void> _validateToken(BuildContext context) async {
    String tokenValue = _controller1.text + _controller2.text + _controller3.text + _controller4.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUuid = prefs.getString('userUuid') ?? userUuid; 

    Map<String, dynamic> body = {
      "userUuid": storedUuid,
      "tokenValue": tokenValue,
    };

    const String apiUrl = "https://0dqw4sfw-3001.usw3.devtunnels.ms/api/v1/token/validar-token";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await prefs.remove('userUuid'); // Borra el UUID después de la validación
        _showAlert(context, "Código de validación enviado correctamente", true);
      } else {
        _showAlert(context, "Error al enviar código de validación: ${response.body}", false);
      }
    } catch (e) {
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TokenActivatedScreen()),
                  );
                }
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
              'Validación',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el código de validación',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 40),
            // Cuadros de entrada para el token
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTokenBox(context, _controller1),
                _buildTokenBox(context, _controller2),
                _buildTokenBox(context, _controller3),
                _buildTokenBox(context, _controller4),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _validateToken(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Validar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para crear cada cuadro de texto del token
  Widget _buildTokenBox(BuildContext context, TextEditingController controller) {
    return SizedBox(
      width: 60,
      height: 80,
      child: TextField(
        controller: controller,
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
  }
}
