import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_cine/services/firebase_service.dart';

import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mothersLastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    _mothersLastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Preparar datos del usuario
        final userData = {
          'firstName': _firstNameController.text,
          'secondName': _secondNameController.text,
          'lastName': _lastNameController.text,
          'mothersLastName': _mothersLastNameController.text,
          'email': _emailController.text,
          'contraseña': _passwordController.text,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Registrar usuario
        final user = await _firebaseService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          userData: userData,
        );

        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en registro: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

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
                key: _formKey,
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
      child: Column(
        children: [
          RegisterFormField(
            label: 'Primer nombre',
            icon: Icons.person_outline,
            controller: _firstNameController,
            validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            label: 'Segundo nombre',
            icon: Icons.person_outline,
            controller: _secondNameController,
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            label: 'Apellido Paterno',
            icon: Icons.person_outline,
            controller: _lastNameController,
            validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            label: 'Apellido Materno',
            icon: Icons.person_outline,
            controller: _mothersLastNameController,
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            label: 'Correo Electrónico',
            icon: Icons.email,
            isEmail: true,
            controller: _emailController,
            validator: (value) {
              if (value!.isEmpty) return 'Campo requerido';
              if (!value.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            label: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            controller: _passwordController,
            validator: (value) {
              if (value!.isEmpty) return 'Campo requerido';
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            label: 'Confirmar Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            controller: _confirmPasswordController,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const CircularProgressIndicator()
              : RegisterButton(onPressed: _registerUser),
        ],
      ),
    );
  }
}

// Widgets actualizados
class RegisterFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isEmail;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const RegisterFormField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.isEmail = false,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
  final VoidCallback onPressed;

  const RegisterButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
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