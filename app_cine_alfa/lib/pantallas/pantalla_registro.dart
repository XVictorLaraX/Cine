import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_cine/servicios/firebase_service.dart';
import 'pantalla_registro_exitoso.dart';

// Pantalla para que los nuevos usuarios se registren
class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _EstadoPantallaRegistro();
}

class _EstadoPantallaRegistro extends State<PantallaRegistro> {
  final FirebaseService _servicioFirebase = FirebaseService();
  final _claveFormulario = GlobalKey<FormState>();

  // Controladores para cada campo del formulario
  final TextEditingController _controladorPrimerNombre = TextEditingController();
  final TextEditingController _controladorSegundoNombre = TextEditingController();
  final TextEditingController _controladorApellidoPaterno = TextEditingController();
  final TextEditingController _controladorApellidoMaterno = TextEditingController();
  final TextEditingController _controladorCorreo = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();
  final TextEditingController _controladorConfirmarContrasena = TextEditingController();

  bool _cargando = false;

  @override
  void dispose() {
    // Limpiar todos los controladores cuando el widget se destruya
    _controladorPrimerNombre.dispose();
    _controladorSegundoNombre.dispose();
    _controladorApellidoPaterno.dispose();
    _controladorApellidoMaterno.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmarContrasena.dispose();
    super.dispose();
  }

  // Método para registrar al usuario
  Future<void> _registrarUsuario() async {
    if (_claveFormulario.currentState!.validate()) {
      // Verificar que las contraseñas coincidan
      if (_controladorContrasena.text != _controladorConfirmarContrasena.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no son iguales')),
        );
        return;
      }

      setState(() => _cargando = true);

      try {
        // Preparar los datos del usuario para Firestore
        final datosUsuario = {
          'nombre': _controladorPrimerNombre.text,
          'segundoNombre': _controladorSegundoNombre.text,
          'apellidoPaterno': _controladorApellidoPaterno.text,
          'apellidoMaterno': _controladorApellidoMaterno.text,
          'correo': _controladorCorreo.text,
          'fechaRegistro': FieldValue.serverTimestamp(),
        };

        // Registrar usuario en Firebase Auth y Firestore
        final usuario = await _servicioFirebase.registerWithEmailAndPassword(
          email: _controladorCorreo.text,
          password: _controladorContrasena.text,
          userData: datosUsuario,
        );

        if (usuario != null) {
          // Navegar a pantalla de éxito si todo sale bien
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => PantallaRegistroExitoso()),
          );
        }
      } catch (error) {
        // Mostrar error si algo falla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrarse: $error')),
        );
      } finally {
        setState(() => _cargando = false);
      }
    }
  }
  // Construir el widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
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
                  children: [
                    const IconoRegistro(),
                    const SizedBox(height: 30),
                    const TituloRegistro(),
                    const SizedBox(height: 40),
                    _construirFormularioRegistro(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
// Constructor del formulario
  Widget _construirFormularioRegistro() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          CampoFormularioRegistro(
            etiqueta: 'Primer nombre',
            icono: Icons.person_outline,
            controlador: _controladorPrimerNombre,
            validador: (valor) => valor!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          const SizedBox(height: 16),
          CampoFormularioRegistro(
            etiqueta: 'Segundo nombre (opcional)',
            icono: Icons.person_outline,
            controlador: _controladorSegundoNombre,
          ),
          const SizedBox(height: 16),
          CampoFormularioRegistro(
            etiqueta: 'Apellido paterno',
            icono: Icons.person_outline,
            controlador: _controladorApellidoPaterno,
            validador: (valor) => valor!.isEmpty ? 'Este campo es obligatorio' : null,
          ),
          const SizedBox(height: 16),
          CampoFormularioRegistro(
            etiqueta: 'Apellido materno (opcional)',
            icono: Icons.person_outline,
            controlador: _controladorApellidoMaterno,
          ),
          const SizedBox(height: 16),
          CampoFormularioRegistro(
            etiqueta: 'Correo electrónico',
            icono: Icons.email,
            esCorreo: true,
            controlador: _controladorCorreo,
            validador: (valor) {
              if (valor!.isEmpty) return 'Ingresa tu correo';
              if (!valor.contains('@')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CampoFormularioRegistro(
            etiqueta: 'Contraseña',
            icono: Icons.lock_outline,
            esContrasena: true,
            controlador: _controladorContrasena,
            validador: (valor) {
              if (valor!.isEmpty) return 'Crea una contraseña';
              if (valor.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CampoFormularioRegistro(
            etiqueta: 'Confirmar contraseña',
            icono: Icons.lock_outline,
            esContrasena: true,
            controlador: _controladorConfirmarContrasena,
            validador: (valor) {
              if (valor != _controladorContrasena.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _cargando
              ? const CircularProgressIndicator()
              : BotonRegistro(alPresionar: _registrarUsuario),
        ],
      ),
    );
  }
}

// Componente para los campos del formulario
class CampoFormularioRegistro extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool esContrasena;
  final bool esCorreo;
  final TextEditingController? controlador;
  final String? Function(String?)? validador;

  const CampoFormularioRegistro({
    super.key,
    required this.etiqueta,
    required this.icono,
    this.esContrasena = false,
    this.esCorreo = false,
    this.controlador,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      validator: validador,
      obscureText: esContrasena,
      keyboardType: esCorreo ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        prefixIconColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

// Botón personalizado para el registro
class BotonRegistro extends StatelessWidget {
  final VoidCallback alPresionar;

  const BotonRegistro({super.key, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text(
          'Crear mi cuenta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class IconoRegistro extends StatelessWidget {
  const IconoRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.person_add,
      size: 50,
      color: Colors.white,
    );
  }
}

class TituloRegistro extends StatelessWidget {
  const TituloRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Regístrate para comenzar',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}