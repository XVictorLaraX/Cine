import 'package:app_cine/navegador/navegador.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_cine/servicios/firebase_service.dart';
import 'pantalla_registro.dart';

class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({super.key});

  @override
  State<PantallaInicioSesion> createState() => _EstadoPantallaInicioSesion();
}
// Pantalla principal para el login
class _EstadoPantallaInicioSesion extends State<PantallaInicioSesion> {
  final FirebaseService _servicioAuth = FirebaseService();
  final _claveFormulario = GlobalKey<FormState>();

  final TextEditingController _controladorCorreo = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();

  bool _cargando = false;
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }
// Formulario de login. Correo y contraseña
  Future<void> _iniciarSesion() async {
    if (_claveFormulario.currentState!.validate()) {
      setState(() => _cargando = true);

      try {
        final usuario = await _servicioAuth.signInWithEmailAndPassword(
          email: _controladorCorreo.text,
          password: _controladorContrasena.text,
        );

        if (usuario != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Navegador()),
          );
        }
        // Posibles errores si los datos no son validos
      } on FirebaseAuthException catch (e) {
        String mensajeError;
        switch (e.code) {
          case 'user-not-found':
            mensajeError = 'No encontramos tu cuenta';
            break;
          case 'wrong-password':
            mensajeError = 'La contraseña no es correcta';
            break;
          case 'invalid-email':
            mensajeError = 'El correo no tiene un formato válido';
            break;
          default:
            mensajeError = 'Ocurrió un error: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algo salió mal: $e')),
        );
      } finally {
        setState(() => _cargando = false);
      }
    }
  }
// Construcción del widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xD7FFFFFF),
              Color(0xFFFF0202),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _claveFormulario,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const IconoCine(),
                    const SizedBox(height: 30),
                    const SizedBox(height: 40),
                    _construirFormularioLogin(),
                    const SizedBox(height: 20),
                    _enlaceRegistro(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
// Formulario
  Widget _construirFormularioLogin() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Campo de correo electrónico
          TextFormField(
            controller: _controladorCorreo,
            validator: (valor) {
              if (valor == null || valor.isEmpty) {
                return 'Necesitamos tu correo';
              }
              if (!valor.contains('@')) {
                return 'El correo no parece válido';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email, color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              labelStyle: const TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Campo de contraseña
          TextFormField(
            controller: _controladorContrasena,
            validator: (valor) {
              if (valor == null || valor.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              if (valor.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
            obscureText: _ocultarContrasena,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock, color: Colors.white),
              suffixIcon: IconButton(
                icon: Icon(
                  _ocultarContrasena ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _ocultarContrasena = !_ocultarContrasena;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              labelStyle: const TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Botón de inicio de sesión
          _cargando
              ? const CircularProgressIndicator()
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _iniciarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enlaceRegistro(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PantallaRegistro(),
          ),
        );
      },
      child: const Text(
        '¿No tienes cuenta? Registrate aquí',
        style: TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// Widget del ícono de cine y titulo
class IconoCine extends StatelessWidget {
  const IconoCine({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.movie_creation,
          size: 100,
          color: Colors.white,
        ),
        const SizedBox(height: 8), // Espacio entre el ícono y el texto
        Text(
          'Cineteca Nacional',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

