package com.example.proyecto_integrador

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle  // Asegúrate de importar Bundle

class MainActivity: FlutterActivity() {

    // No es necesario registrar manualmente los plugins en Flutter 2.x
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Si tu proyecto usa plugins, Flutter se encarga de registrarlos automáticamente
    }
}
