import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'verification_fp_screen.dart'; // Importa la vista de verificación

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
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

  Future<void> _onSubmit() async {
    if (!_isGmailSelected && !_isWhatsAppSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una opción para recuperar tu contraseña.')),
      );
      return;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese su correo.')),
      );
      return;
    }

    String selectedOption = _isGmailSelected ? "email" : "whatsapp";

    Map<String, dynamic> requestBody = {
      "email": _emailController.text,
      "notificationPreference": selectedOption,
    };

    try {
      const String apiUrl = 'https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/reset/password-reset';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Redirige a la vista de verificación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerificationFpScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Olvidaste tu contraseña?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ingrese su correo',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              const Text(
                'Elige una opción para poder recuperar tu contraseña',
                style: TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isGmailSelected,
                onChanged: _onGmailChanged,
                title: const Text('Gmail'),
                secondary: const Icon(Icons.email, color: Colors.red),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _isWhatsAppSelected,
                onChanged: _onWhatsAppChanged,
                title: const Text('WhatsApp'),
                secondary: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Siguiente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Recuerdas tu contraseña? ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Color.fromRGBO(118, 215, 196, 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
