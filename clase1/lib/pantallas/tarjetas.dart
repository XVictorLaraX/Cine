import 'package:flutter/material.dart';

class Tarjetas extends StatefulWidget {
  Tarjetas({
    super.key,
    required this.nombres,
    required this.descripciones,
    required this.rutas,
    required this.height,
    required this.width,
    required this.color,
  });

  List<String> nombres;
  List<String> descripciones;
  List<String> rutas;
  double height;
  double width;
  Color color;

  @override
  State<Tarjetas> createState() => _TarjetasState();
}

class _TarjetasState extends State<Tarjetas> {
  final List<Widget> _tarjetas = [];

  void _cargarTarjetas() {
    if (widget.nombres.isEmpty) {
      print("Error en tarjetas: No se enviaron datos");
      return;
    }

    if (widget.nombres.length != widget.descripciones.length || widget.nombres.length != widget.rutas.length) {
      print("Error en tarjetas: Las listas no tienen la misma longitud");
      return;
    }

    setState(() {
      for (int i = 0; i < widget.nombres.length; i++) {
        _tarjetas.add(
            SizedBox(
              width: widget.width * 0.9, // Ajustar el tamaño máximo de la tarjeta
              child: Card(
                color: widget.color,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: widget.width/5, // Definir el tamaño de la imagen
                      height: widget.height/5,
                      child: ClipRRect(
                          child:
                          Image.asset(widget.rutas[i], fit: BoxFit.cover)),
                    ),
                    SizedBox(
                      width: 50,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.nombres[i]),
                        Text(widget.descripciones[i]),
                      ],
                    ),
                  ],
                ),
              ),
            )        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarTarjetas();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _tarjetas,
    );
  }
}