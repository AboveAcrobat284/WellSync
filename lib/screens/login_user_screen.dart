import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'inactive_token_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});

  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = true; // Variable para mostrar la animación de carga

  Future<void> _loginUser() async {
    final String correo = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      _showAlert(context, "Por favor, complete todos los campos.", false);
      return;
    }

    const String apiUrl = "https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/users/login";
    Map<String, dynamic> body = {
      "correo": correo,
      "password": password,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("Respuesta de la API de login: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('token') &&
            responseData.containsKey('userUuid') &&
            responseData.containsKey('leadUuid')) {
          final String token = responseData['token'];
          final String userUuid = responseData['userUuid'];
          final String leadUuid = responseData['leadUuid'];
          print("Token recibido: $token");

          // Guardar el token y los UUIDs en SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('userUuid', userUuid);
          await prefs.setString('leadUuid', leadUuid);

          // Mostrar mensaje de éxito y redirigir al HomeScreen con isLoggedIn = true
          _showAlert(context, "Inicio de sesión exitoso, bienvenido.", true, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen(isLoggedIn: true)),
            );
          });
        } else {
          print("Error: La respuesta no contiene los UUIDs necesarios.");
          _showAlert(context, "Error: La respuesta no contiene los UUIDs necesarios.", false);
        }
      } else {
        _showAlert(context, "Error al iniciar sesión: ${response.body}", false);
      }
    } catch (e) {
      print("Error de conexión: $e");
      _showAlert(context, "Error de conexión: $e", false);
    }
  }

  Future<void> _checkIfLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final String? userUuid = prefs.getString('userUuid');
    final String? leadUuid = prefs.getString('leadUuid');

    if (token != null && userUuid != null && leadUuid != null) {
      // El usuario ya está logueado, redirigir al HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen(isLoggedIn: true)),
      );
    } else {
      setState(() {
        _isLoading = false; // Dejar de mostrar la animación de carga
      });
    }
  }

  void _showAlert(BuildContext context, String message, bool isSuccess, [VoidCallback? onDismiss]) {
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
                if (isSuccess && onDismiss != null) {
                  onDismiss();
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
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      await _checkIfLoggedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Cargando...", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
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
                    const SizedBox(height: 36),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8ECF4),
                        labelText: 'Ingresa tu contraseña',
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: Color.fromRGBO(118, 215, 196, 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 66),
                    ElevatedButton(
                      onPressed: _loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 102),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No tienes cuenta?',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Registrate aquí',
                            style: TextStyle(
                              color: Color.fromRGBO(118, 215, 196, 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InactiveTokenScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Activa tu cuenta',
                            style: TextStyle(
                              color: Color.fromRGBO(118, 215, 196, 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
