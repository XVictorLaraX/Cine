import 'package:flutter/material.dart';

class Calcu extends StatefulWidget{
  const Calcu({super.key, required this.titulo});

  final String titulo;
  @override
  State<Calcu> createState() => _CalcuState();
}

class _CalcuState extends State<Calcu>{

  String _respuestaS="";
  double _respuesta=0;
  double _a=0;
  int _op=0;
  bool _punto=false;

  final List<List<dynamic>> _textoBotones=[
    [7,8,9,"/"],
    [4,5,6,"*"],
    [1,2,3,"-"],
    [0,".","=","+"]
  ];

  Widget _tecladoCalcu(BuildContext context, double h, double w){
    List<Widget> filas=[];
    for(int i=0;i<4;i++){
      List<Widget> botones=[];
      for(int j=0;j<4;j++){
        botones.add(
          MaterialButton(
            shape: Border.all(
              color: Colors.white,
            ),
            color: Colors.black,
            onPressed: (){
              _presionaNumero(_textoBotones[i][j]);
            },
            child: Text(
              "${_textoBotones[i][j]}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
        );
        botones.add(
          SizedBox(
            width: w,
          )
        );
      }
      filas.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: botones,
        )
      );
      filas.add(
          SizedBox(
            height: h,
          )
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: filas,
    );
  }

  void _presionaNumero(dynamic s) {
    if (s is int) {
      setState(() {
        _respuestaS += s.toString();
        _respuesta = double.parse(_respuestaS);
      });
    }

    if (s == "=") {
      if (_op == 1) {
        setState(() {
          _respuesta = _opera(1);
          _respuestaS = "";
          _op = 0;
          _punto = false;
          _a = 0;
        });
      }
      if (_op == 2) {
        setState(() {
          _respuesta = _opera(2);
          _respuestaS = "";
          _op = 0;
          _punto = false;
          _a = 0;
        });
      }
      if (_op == 3) {
        setState(() {
          _respuesta = _opera(3);
          _respuestaS = "";
          _op = 0;
          _punto = false;
          _a = 0;
        });
      }
      if (_op == 4) {
        setState(() {
          _respuesta = _opera(4);
          _respuestaS = "";
          _op = 0;
          _punto = false;
          _a = 0;
        });
      }
      else {
        setState(() {
          _respuesta = _respuesta;
        });
      }
    }

    if (s is String) {
      if (s == ".") {
        if (!_punto) {
          setState(() {
            _punto = true;
            _respuestaS += ".";
          });
        }
      }

      if (s == "+") {
        if (_op == 0) {
          setState(() {
            _op = 1;
            _a = _respuesta;
            _respuesta = 0;
            _respuestaS = "";
            _punto = false;
          });
        }
        else {
          setState(() {
            _respuesta = _opera(_op);
            _a = _respuesta;
            _op = 1;
            _respuestaS = "";
            _punto = false;
          });
        }
      }
      if (s == "-") {
        if (_op == 0) {
          setState(() {
            _op = 2;
            _a = _respuesta;
            _respuesta = 0;
            _respuestaS = "";
            _punto = false;
          });
        }
        else {
          setState(() {
            _respuesta = _opera(_op);
            _a = _respuesta;
            _op = 2;
            _respuestaS = "";
            _punto = false;
          });
        }
      }
      if (s == "*") {
        if (_op == 0) {
          setState(() {
            _op = 3;
            _a = _respuesta;
            _respuesta = 0;
            _respuestaS = "";
            _punto = false;
          });
        }
        else {
          setState(() {
            _respuesta = _opera(_op);
            _op = 3;
            _a = _respuesta;
            _respuestaS = "";
            _punto = false;
          });
        }
      }
      if (s == "/") {
        if (_op == 0) {
          setState(() {
            _op = 4;
            _a = _respuesta;
            _respuesta = 0;
            _respuestaS = "";
            _punto = false;
          });
        }
        else {
          setState(() {
            _respuesta = _opera(_op);
            _a = _respuesta;
            _op = 4;
            _respuestaS = "";
            _punto = false;
          });
        }
      }
    }
  }

  double _opera(int op){
    if(op==1){
      return _a+_respuesta;
    }
    if(op==2){
      return _a-_respuesta;
    }
    if(op==3){
      return _a*_respuesta;
    }
    if(op==4){
      return _a/_respuesta;
    }
    else{
      return 0;
    }
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
        title:Text("Calcu"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                    width: 320,
                    color : Colors.blue,
                    child: Text(
                      "$_respuesta",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 32,
                      ),
                    ),
                  ),
                ]
            ),//Cuadro para mostrar el numero
            _tecladoCalcu(context,2,2)
          ],
        ),
      ),
    );
  }
}
