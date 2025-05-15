import 'package:app_cine/pantallas/pantalla_principal_cine.dart';
import 'package:app_cine/pantallas/pantalla_inicio_sesion.dart';
import 'package:app_cine/pantallas/pantalla_ubicacion.dart';
import 'package:app_cine/pantallas/pantalla_mis_boletos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Maneja la navegación entre las diferentes secciones
class Navegador extends StatefulWidget {
  const Navegador({super.key});

  @override
  State<Navegador> createState() => _EstadoMenuPrincipal();
}

class _EstadoMenuPrincipal extends State<Navegador> {
  // Controla qué sección está visible actualmente
  int _seccionActual = 0;

  // Todas las pantallas disponibles en nuestra app
  final List<Widget> _secciones = [
    const PantallaPrincipalCine(), // Cartelera de películas
    const PantallaMisBoletos(),    // Boletos comprados
    const PantallaUbicacion(),     // Mapa de ubicación
  ];

  // Cambia a una nueva sección cuando el usuario toca un botón
  void _mostrarSeccion(int indiceSeccion) {
    setState(() {
      _seccionActual = indiceSeccion;
    });
  }

  // Cierra la sesión del usuario y lo lleva de vuelta al login
  Future<void> _salirDeLaCuenta() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Verificamos que el widget aún esté en el árbol de widgets
      if (!mounted) return;

      // Navegamos al login y eliminamos todas las rutas anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
            (Route<dynamic> ruta) => false,
      );
    } catch (error) {
      // Mostramos error si algo falla
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oops! No pudimos cerrar sesión: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cineteca Nacional'),
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _salirDeLaCuenta,
            tooltip: 'Salir de la cuenta',
          ),
        ],
        // Barra de navegación inferior personalizada
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botón para la cartelera
                _BotonMenu(
                  icono: Icons.movie_filter,
                  texto: 'Estrenos',
                  seleccionado: _seccionActual == 0,
                  alTocar: () => _mostrarSeccion(0),
                ),
                // Botón para los boletos
                _BotonMenu(
                  icono: Icons.confirmation_number,
                  texto: 'Mis entradas',
                  seleccionado: _seccionActual == 1,
                  alTocar: () => _mostrarSeccion(1),
                ),
                // Botón para la ubicación
                _BotonMenu(
                  icono: Icons.place,
                  texto: 'Cómo llegar',
                  seleccionado: _seccionActual == 2,
                  alTocar: () => _mostrarSeccion(2),
                ),
              ],
            ),
          ),
        ),
      ),
      // Muestra la sección actual
      body: _secciones[_seccionActual],
    );
  }
}

// Botón personalizado para el menú de navegación
class _BotonMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool seleccionado;
  final VoidCallback alTocar;

  const _BotonMenu({
    required this.icono,
    required this.texto,
    required this.seleccionado,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: seleccionado ? Colors.white : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: seleccionado ? Colors.white : Colors.white70),
            const SizedBox(width: 6.0),
            Text(
              texto,
              style: TextStyle(
                color: seleccionado ? Colors.white : Colors.white70,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}