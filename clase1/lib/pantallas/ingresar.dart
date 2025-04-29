import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Ingresar extends StatefulWidget{
  const Ingresar({super.key,required this.titulo,required this.funcionCambio});

  final String titulo;
  final Function funcionCambio;
  @override
  State<Ingresar> createState() => _IngresarState();

}

class _IngresarState extends State<Ingresar>{

  final TextEditingController _controller = TextEditingController();

  Future<SharedPreferences> _obtenerPreferenncias() async{
    final SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs;
  }

  Future<void> _escribirDatos(String s) async{
    SharedPreferences prefs= await _obtenerPreferenncias();
    await prefs.setString("Kevin",s);
  }

  @override
  void initState(){
    super.initState();
  }
  @override

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title:Text("Ingresa tu nombre"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ingresa tu nombre:",
              style: TextStyle
                (fontSize: 40,
              ),
            ),
            SizedBox(
              width: 400,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: TextStyle
                  (fontSize: 35,
                ),
              ),
            ),
            SizedBox(
              height: 25,
            ),
            MaterialButton(
              onPressed: (){
                _escribirDatos(_controller.text);
                _controller.text="";
                widget.funcionCambio(1);
              },
              color: Theme.of(context).colorScheme.inversePrimary,
              child: Text("Enviar",
                style: TextStyle
                  (fontSize: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}