import 'package:clase1/pantallas/ingresar.dart';
import 'package:clase1/pantallas/localizacion.dart';
import 'package:clase1/pantallas/principal.dart';
import 'package:flutter/material.dart';
import 'package:clase1/pantallas/segunda.dart';
import 'package:clase1/pantallas/calcu.dart';
import 'package:clase1/pantallas/calendario.dart';
import 'package:clase1/pantallas/personalizado.dart';

class Navegador extends StatefulWidget{
  const Navegador({super.key});

  @override
  State<Navegador> createState() => _NavegadorState();

}


class _NavegadorState extends State<Navegador> {

  int _p=6;

  final List<Widget> _pantallas=[];
  Widget _cuerpo=MyHomePage(title: "ola ke ase");
  // Widget _cuerpo=Otra(title: "La otra");

  void _cambiaPantalla(int v){
    _p=v;
    setState(() {
      _cuerpo=_pantallas[_p];
    });
  }

  @override
  void initState(){
    super.initState();
    _pantallas.add(const MyHomePage(title: "ola ke ase"));
    _pantallas.add(const Bienvenida(titulo: "La otra"));
    _pantallas.add(const Calcu(titulo:"Calcu"));
    _pantallas.add(Ingresar(titulo:"Ingresa tu nombre", funcionCambio: _cambiaPantalla,));
    _pantallas.add(const Localizacion(titulo: "Localizacion",));
    _pantallas.add(const Calendario(titulo: "Agenda"));
    _pantallas.add(const Bienvenidas(titulo: "Imagenes"));
    _cuerpo=_pantallas[_p];
  }
  @override

  Widget build(BuildContext context){
    return Scaffold(
      body: _cuerpo,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _p,
        onTap: (value) {
          _cambiaPantalla(value);
        },
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            label: "MyHomePage",
            icon: Icon(
              Icons.home,
            ),
          ),
          BottomNavigationBarItem(
            label: "Bienvenida",
            icon: Icon(
              Icons.handshake_sharp,
            ),
          ),
          BottomNavigationBarItem(
            label: "Calcu",
            icon: Icon(
              Icons.calculate,
            ),
          ),
          BottomNavigationBarItem(
            label: "Ingresa",
            icon: Icon(
              Icons.transit_enterexit,
            ),
          ),
          BottomNavigationBarItem(
            label: "Localizacion",
            icon: Icon(
              Icons.local_activity_outlined,
            ),
          ),
          BottomNavigationBarItem(
            label: "Agenda",
            icon: Icon(
              Icons.calendar_month,
            ),
          ),
          BottomNavigationBarItem(
            label: "Personalizado",
            icon: Icon(
              Icons.accessibility,
            ),
          ),
        ],
      ),

    );
  }
}