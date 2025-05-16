import 'package:flutter/material.dart';

// Pantalla que aparece cuando te registras sin problemas
class PantallaRegistroExitoso extends StatelessWidget {
  const PantallaRegistroExitoso({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Muestra la barra superior con el título siguiente
      appBar: AppBar(
        title: const Text('Todo listo'),
      ),

      // El cuerpo o centro de la pantalla
      body: const Center(
        child: Text(
          '¡Listo! Ya estás registrado', // Mensaje de regitro
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}