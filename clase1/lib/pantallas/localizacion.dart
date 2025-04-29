import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Localizacion extends StatefulWidget{
  const Localizacion({super.key,required this.titulo});

  final String titulo;
  @override
  State<Localizacion> createState() => _LocalizacionState();

}

class _LocalizacionState extends State<Localizacion>{

  String _latitud="";
  String _longitud="";

  Future<Position> _determinarPosicion() async{
    bool serviceEnabled;
    LocationPermission permiso;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      return Future.error('La localizacion esta desactivada');
    }

    permiso = await Geolocator.checkPermission();
    if(permiso==LocationPermission.denied){
      permiso = await Geolocator.requestPermission();
      if(permiso==LocationPermission.denied){
        return Future.error('Los permisos de localizacion fueron denegados');
      }
    }

    if(permiso==LocationPermission.deniedForever){
      return Future.error(
        'Los permisos de localizacion fueron denegados permanentemente, no podemos dar tu localizacion'
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  void _obCoor() async{
    Position posicion= await _determinarPosicion();
    setState(() {
      _latitud=posicion.latitude.toString();
      _longitud=posicion.longitude.toString();
    });
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
        title:Text("Localizacion"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Localizacion",
              style: TextStyle
                (fontSize: 40,
              ),
            ),
            MaterialButton(
              shape: Border.all(
                color: Colors.white,
              ),
              color: Colors.black,
              onPressed:(){
                _obCoor();
              },
              child: Text("Obtener coordenadas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
            ),
            SizedBox(
              height: 25,
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:[
                  Text(
                    "Latitud: $_latitud",
                    style: TextStyle
                      (fontSize: 32,
                    ),
                  )
                ]
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:[
                  Text(
                    "Longitud: $_longitud",
                    style: TextStyle
                      (fontSize: 32,
                    ),
                  )
                ]
            ),
          ],
        ),
      ),
    );
  }
}