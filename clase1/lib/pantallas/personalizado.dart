import 'package:flutter/material.dart';
import 'package:clase1/pantallas/tarjetas.dart';

class Bienvenidas extends StatefulWidget{
  const Bienvenidas({super.key, required this.titulo});

  final String titulo;
  @override
  State<Bienvenidas> createState() => _BienvenidasState();

}

class _BienvenidasState extends State<Bienvenidas> {

  @override
  void initState(){
    super.initState();
  }
  @override

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title:Text("Hola"),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Tarjetas(
            width: 500,
            height: 600,
            color: Colors.yellow,
            nombres:["John Cena y Randy Orton", "CMpunk","Penta","John Cena y Randy Orton", "CMpunk","Penta"],
            descripciones: ["RKO","Cm","El Cero Miedo","RKO","Cm","El Cero Miedo"],
            rutas: ["assets/images/JohnCena.webp",
                    "assets/images/CmPunk.webp",
                    "assets/images/pentazeromiedo.webp",
                    "assets/images/JohnCena.webp",
                    "assets/images/CmPunk.webp",
                    "assets/images/pentazeromiedo.webp"],
          ),
        ),
      ));
  }
}