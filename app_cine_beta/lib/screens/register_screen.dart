import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),),
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
              child: Column(
                children: [
                  const RegisterIcon(),
                  const SizedBox(height: 30),
                  const RegisterTitle(),
                  const SizedBox(height: 40),
                  _buildRegisterForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          RegisterFormField(
            label: 'Nombre(s)',
            icon: Icons.person_outline,
          ),
          SizedBox(height: 16),
          RegisterFormField(
            label: 'Apellido Paterno',
            icon: Icons.person_outline,
          ),
          SizedBox(height: 16),
          RegisterFormField(
            label: 'Apellido Materno',
            icon: Icons.person_outline,
          ),
          SizedBox(height: 16),
          RegisterFormField(
            label: 'Correo Electrónico',
            icon: Icons.email,
            isEmail: true,
          ),
          SizedBox(height: 16),
          RegisterFormField(
            label: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          SizedBox(height: 16),
          RegisterFormField(
            label: ' Confirmar Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          SizedBox(height: 24),
          RegisterButton(),

        ],
      ),
    );
  }
}

// Widgets reutilizables para registro
class RegisterIcon extends StatelessWidget {
  const RegisterIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.movie_filter,
      size: 80,
      color: Colors.white,
    );
  }
}

class RegisterTitle extends StatelessWidget {
  const RegisterTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Crear nueva cuenta',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class RegisterFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isEmail;

  const RegisterFormField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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

class RegisterButton extends StatelessWidget {
  const RegisterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Lógica de registro
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text(
          'Registrarse',
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