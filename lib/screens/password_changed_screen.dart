import 'package:flutter/material.dart';
import 'login_user_screen.dart'; // Importar la pantalla de inicio de sesión

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de "check" en un círculo verde
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(118, 215, 196, 1), // Color de fondo del círculo
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Texto de confirmación de restablecimiento
            const Text(
              'Contraseña restablecida',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtítulo
            const Text(
              'Tu contraseña se ha restablecido correctamente',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Botón para regresar al inicio
            ElevatedButton(
              onPressed: () {
                // Redirigir a la pantalla de inicio de sesión
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginUserScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Regresar al inicio',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
