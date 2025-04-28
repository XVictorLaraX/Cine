import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // 1. Crear usuario en Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Verificar que el usuario fue creado correctamente
      if (userCredential.user == null) return null;

      // 3. Guardar datos en documento específico usando UID
      await _firestore
          .collection('Usuarios') // Nombre exacto de tu colección existente
          .doc(userCredential.user!.uid) // Usar UID como ID de documento
          .set(userData, SetOptions(merge: true)); // Merge evita sobrescribir datos existentes

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error de Firebase Auth: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("Error general: $e");
      return null;
    }
  }
}
class RegisterIcon extends StatelessWidget {
  const RegisterIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.person_add,  // Puedes cambiar el icono
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