import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  double _counter = 0;
  final double _valorFijo = 5;

  String _texto="";

  void _obDatosB()async{
    DocumentSnapshot documento = await db.collection("sumador").doc("documento").get();
    setState(() {
      _counter=documento.get("numero");
    });
  }

  void _esBase() async{
    Map<String,dynamic> datos = {
      "numero":_counter
    };
    await db.collection("sumador").doc("documento").set(datos);
  }

  void _cambiaCaracter(String caracterViejo, String cadenaNueva){
    setState(() {
      _texto=_texto.replaceAll(caracterViejo,cadenaNueva);
    });
  }

  void _incrementCounter() {
    Random r=Random();

    int c = 97+r.nextInt(26);
    setState(() {
      _texto+=String.fromCharCode(c);
      _counter+=_valorFijo;
      _esBase();
    });
  }
  void _decrementCounter() {
    setState(() {
      if(_counter>=_valorFijo){
        _texto=_texto.substring(0,_texto.length-1);
        _counter-=_valorFijo;
        _esBase();
      }
      if(_counter<_valorFijo){
        _counter=0;
      }
    });
  }

  @override
  void initState(){
    super.initState();
    _obDatosB();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      drawer: Drawer(
        child:
        Center(

      child: Column(

      mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '2860',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(
            height: 125,
            child: Image.network(
                "https://static.vecteezy.com/system/resources/previews/017/047/852/non_2x/cute-chibi-dinosaur-illustration-dinosaur-kawaii-drawing-style-dinosaur-cartoon-vector.jpg"
            ),

          ),

          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          FloatingActionButton(
            onPressed: _decrementCounter,
            tooltip: 'Resta',
            child: const Text("Adios"),
          ),
          Text(
            _texto,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          IconButton(
              icon: Icon(Icons.directions_car_filled),
              onPressed: (){
                _cambiaCaracter("m", "n");
              }
          ),
        ],
      ),
    ),

      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '2860',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(
              height: 125,
              child: Image.network(
                  "https://static.vecteezy.com/system/resources/previews/017/047/852/non_2x/cute-chibi-dinosaur-illustration-dinosaur-kawaii-drawing-style-dinosaur-cartoon-vector.jpg"
              ),

            ),

            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            FloatingActionButton(
              onPressed: _decrementCounter,
              tooltip: 'Resta',
              child: const Text("Adios"),
            ),
            Text(
              _texto,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            IconButton(
              icon: Icon(Icons.directions_car_filled),
              onPressed: (){
                _cambiaCaracter("m", "n");
              }
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.

    );
  }
}
