import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Establecer el fondo de toda la pantalla como blanco
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Mantener el fondo transparente del AppBar
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(186, 234, 225, 1), // Fondo de color rgba
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrar todo el contenido
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Texto centrado en la parte superior
            const Text(
              'Obtener más monedas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30), // Espacio entre el texto y el siguiente bloque

            // Fondo blanco con sombra
            Container(
              width: double.infinity, // Hacer que ocupe todo el ancho disponible
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Centrar la fila
                children: [
                  // Imagen de la moneda a la izquierda
                  Image.asset(
                    'assets/coins.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover, // Ajusta la imagen para cubrir el contenedor
                  ),
                  const SizedBox(width: 40), // Espacio entre la imagen y el texto

                  // Texto a la derecha de la imagen
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        '100', // Cantidad de monedas
                        style: TextStyle(
                          fontSize: 22, // Tamaño de texto más grande
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'MXN 25', // Precio en MXN
                        style: TextStyle(
                          fontSize: 18, // Tamaño de texto más grande
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Botón de "Comprar"
                      ElevatedButton(
                        onPressed: null, // Aquí iría la lógica para comprar

                        child: Text(
                          'Comprar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
