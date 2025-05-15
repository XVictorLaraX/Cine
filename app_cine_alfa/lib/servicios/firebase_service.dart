import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro de usuario
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

      // 3. Guardar datos adicionales en Firestore
      await _firestore
          .collection('Usuarios')
          .doc(userCredential.user!.uid)
          .set({
        ...userData,
        'uid': userCredential.user!.uid, // Añadir UID a los datos
        'email': email, // Asegurar que el email está incluido
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error de Firebase Auth: ${e.message}");
      rethrow; // Cambiado de return null a rethrow para manejar en UI
    } catch (e) {
      debugPrint("Error general: $e");
      rethrow;
    }
  }

  // Inicio de sesión
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error de login: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Error general en login: $e");
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
      rethrow;
    }
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('Usuarios')
            .doc(user.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint("Error obteniendo datos de usuario: $e");
      return null;
    }
  }

  // Verificar si el usuario está autenticado
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

// Widgets reutilizables (pueden moverse a archivo aparte)
class RegisterIcon extends StatelessWidget {
  const RegisterIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.person_add,
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