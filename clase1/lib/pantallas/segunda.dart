import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bienvenida extends StatefulWidget{
  const Bienvenida({super.key, required this.titulo});

  final String titulo;
  @override
  State<Bienvenida> createState() => _BienvenidaState();

}

class _BienvenidaState extends State<Bienvenida> {
  String _Nombre="";

  Future<SharedPreferences> _obtenerPreferenncias() async{
    final SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs;
  }

  Future<void> _leerDatos() async{
    SharedPreferences prefs= await _obtenerPreferenncias();
    String? aux= prefs.getString("Kevin");
    if(aux!=null){
      setState(() {
        _Nombre=aux;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    _leerDatos();
  }
  @override

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title:Text("Hola"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenid@",
              style: TextStyle(
                fontSize: 40,
              ),
            ),
            Text(_Nombre,
              style: TextStyle(
                fontSize: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}