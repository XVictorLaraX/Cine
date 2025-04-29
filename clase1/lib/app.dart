import 'package:clase1/navegador.dart';
import 'package:flutter/material.dart';
//import 'Pantallas/principal.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juan Point',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellowAccent,
        ),
        useMaterial3: true,
      ),
      home: Navegador(),
    );
  }
}
