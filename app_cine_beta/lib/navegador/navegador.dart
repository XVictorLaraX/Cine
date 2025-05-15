import 'package:app_cine/pantallas/pantalla_principal_cine.dart';
import 'package:app_cine/pantallas/inicio_sesion_pantalla.dart';
import 'package:app_cine/pantallas/ubicacion_pantalla.dart';
import 'package:app_cine/pantallas/mis_boletos_pantalla.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Pantalla principal que permite navegar entre cartelera, boletos y ubicación
class CineNavegador extends StatefulWidget {
  const CineNavegador({super.key});

  @override
  State<CineNavegador> createState() => _EstadoCineNavegador();
}

class _EstadoCineNavegador extends State<CineNavegador> {
  // Índice que indica qué pantalla se está mostrando actualmente
  int _indicePantallaActual = 0;

  // Lista de las pantallas que se pueden mostrar
  final List<Widget> _pantallas = [
    const PantallaPrincipalCine(),
    const MisBoletosPantalla(),
    const UbicacionPantalla(),
  ];

  // Cambiar de pantalla cuando el usuario selecciona una opción
  void _cambiarPantalla(int indice) {
    setState(() {
      _indicePantallaActual = indice;
    });
  }

  // Cierra la sesión actual del usuario y lo redirige al inicio de sesión
  Future<void> _cerrarSesion() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const InicioSesionPantalla()),
            (Route<dynamic> ruta) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cineteca Nacional'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BotonNavegacion(
                  icono: Icons.movie,
                  etiqueta: 'Cartelera',
                  activo: _indicePantallaActual == 0,
                  alPresionar: () => _cambiarPantalla(0),
                ),
                BotonNavegacion(
                  icono: Icons.confirmation_num,
                  etiqueta: 'Mis boletos',
                  activo: _indicePantallaActual == 1,
                  alPresionar: () => _cambiarPantalla(1),
                ),
                BotonNavegacion(
                  icono: Icons.location_on,
                  etiqueta: 'Ubicación',
                  activo: _indicePantallaActual == 2,
                  alPresionar: () => _cambiarPantalla(2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _pantallas[_indicePantallaActual],
    );
  }
}

// Botón de navegación personalizado para cambiar entre secciones
class BotonNavegacion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback alPresionar;

  const BotonNavegacion({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPresionar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: activo ? Colors.white : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: activo ? Colors.white : Colors.white70),
            const SizedBox(width: 8.0),
            Text(
              etiqueta,
              style: TextStyle(
                color: activo ? Colors.white : Colors.white70,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
