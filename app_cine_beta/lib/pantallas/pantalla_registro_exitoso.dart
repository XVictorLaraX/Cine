import 'package:flutter/material.dart';

// Pantalla que aparece cuando te registras sin problemas
class PantallaRegistroExitoso extends StatelessWidget {
  const PantallaRegistroExitoso({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La barrita de arriba con el título
      appBar: AppBar(
        title: const Text('Todo listo'),
      ),

      // Lo que se ve en el centro de la pantalla
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