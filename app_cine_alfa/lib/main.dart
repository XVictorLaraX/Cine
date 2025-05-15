import 'package:app_cine/navegador/navegador.dart';
import 'package:flutter/material.dart';
import 'pantallas/pantalla_inicio_sesion.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CineApp());
}

// En main.dart
class CineApp extends StatelessWidget {
  const CineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cine App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PantallaInicioSesion(),
      routes: {
        '/home': (context) => const Navegador(),
      },
    );
  }
}