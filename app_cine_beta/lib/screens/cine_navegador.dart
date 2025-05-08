import 'package:app_cine/screens/cine_home_screen.dart';
import 'package:app_cine/screens/login_screen.dart';
import 'package:app_cine/screens/ubicacion_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CineNavegador extends StatefulWidget {
  const CineNavegador({super.key});

  @override
  State<CineNavegador> createState() => _CineNavegadorState();
}

class _CineNavegadorState extends State<CineNavegador> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = [
    const CineHomeScreen(),
    const UbicacionScreen(),
  ];

  void _cambiarPantalla(int indice) {
    setState(() {
      _indiceActual = indice;
    });
  }
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
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
            onPressed: _signOut,
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
                _BotonNavegacion(
                  icono: Icons.movie,
                  etiqueta: 'Cartelera',
                  activo: _indiceActual == 0,
                  onTap: () => _cambiarPantalla(0),
                ),
                _BotonNavegacion(
                  icono: Icons.location_on,
                  etiqueta: 'Ubicación',
                  activo: _indiceActual == 1,
                  onTap: () => _cambiarPantalla(1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _pantallas[_indiceActual],
    );
  }
}

class _BotonNavegacion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  const _BotonNavegacion({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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