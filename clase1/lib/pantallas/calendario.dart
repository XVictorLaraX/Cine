import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';


class Calendario extends StatefulWidget {
  const Calendario({super.key, required this.titulo});
  final String titulo;
  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  final TextEditingController _nombreEvento = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  final List<Meeting> meetings = <Meeting>[];
  final List<String> _nombresEventos=[];
  final List<Map<String,dynamic>> _eventos=[];
  DateTime? _fechaIn = DateTime.now();
  DateTime? _fechaFin = DateTime.now();
  int ? _color;
  bool _tD = false;

  void _setMeeting() async{
    Map<String,dynamic> datos = {
      "color":_color,
      "fechaFinal":_fechaFin,
      "fechaInicio":_fechaIn,
      "todoDia":_tD
    };
    await db.collection("eventos").doc(_nombreEvento.text).set(datos);
  }

  void _getMeeting() async{
    QuerySnapshot eventos = await db.collection("eventos").get();
    for(DocumentSnapshot evento in eventos.docs){
      _nombresEventos.add(evento.id);
      _eventos.add(evento.data() as Map<String,dynamic>);
    }
  }

  void _fijarFechaInicial(DateTime fechaNue){
    setState(() {
      _fechaIn=fechaNue;
    });
  }

  void _fijarFechaFinal(DateTime fechaNue){
    setState(() {
      _fechaFin=fechaNue;
    });
  }

  void _muestraColor(){
    showDialog(context: context, builder: (BuildContext context)
    {
      return AlertDialog(
        title: const Text("Color"),
        content: ColorPicker(
            onColorChanged: (value){
              _color=value.value32bit;
            },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Aceptar"),
          ),
        ],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _getMeeting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      SfCalendar(
        view: CalendarView.month,
        dataSource: MeetingDataSource(_getDataSource(_nombresEventos,_eventos)),
        monthViewSettings: MonthViewSettings(
          showAgenda: true,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:[
                      TextField(controller: _nombreEvento,),
                      Text(
                        "Nombre del evento",
                        style: TextStyle
                          (fontSize: 15,
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      SizedBox(
                        child: CupertinoCalendarPickerButton(
                          minimumDateTime: DateTime(2024, 7, 10),
                          maximumDateTime: DateTime(2025, 7, 10),
                          initialDateTime: DateTime.now(),
                          currentDateTime: DateTime.now(),
                          mode: CupertinoCalendarMode.dateTime,
                          timeLabel: 'Ends',
                          onDateTimeChanged: (date) {
                            _fijarFechaInicial(date);
                          },),
                      ),
                      Text(
                        "Fecha Inicial",
                        style: TextStyle
                          (fontSize: 15,
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      SizedBox(
                        child: CupertinoCalendarPickerButton(
                          minimumDateTime: DateTime(2024, 7, 10),
                          maximumDateTime: DateTime(2025, 7, 10),
                          initialDateTime: DateTime.now(),
                          currentDateTime: DateTime.now(),
                          mode: CupertinoCalendarMode.dateTime,
                          timeLabel: 'Ends',
                          onDateTimeChanged: (date) {
                            _fijarFechaFinal(date);
                          },),
                      ),
                      Text(
                        "Fecha Final",
                        style: TextStyle
                          (fontSize: 15,
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      TextButton(
                          onPressed: (){
                            _muestraColor();
                          },
                          child: Text("Elije un color"),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setDialogState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("¿Dura todo el dia?: ", style: TextStyle(fontSize: 15)),
                                Checkbox(
                                  value: _tD,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      _tD = value ?? false;// Actualiza el estado dentro del diálogo
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                        },
                      ),
                      SizedBox(
                        height: 25,
                      ),
                    ]
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: (){
                        _setMeeting();

                        _nombreEvento.text = "";
                        _fechaIn=DateTime.now();
                        _fechaFin=DateTime.now();
                        _color=0;
                        _tD=false;
                        Navigator.of(context).pop();
                      },
                      child: Text("Agendar"))
                ],
                title: const Text(
                  "Evento",
                  style: TextStyle(
                    fontSize:32,
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.help),
      ),
    );
  }

  List<Meeting> _getDataSource(List<String> nombresEventos, List<Map<String,dynamic>> eventos) {
    for(int i=0;i<nombresEventos.length;i++){
      DateTime fechaInicio=(eventos[i]["fechaInicio"] as Timestamp).toDate();
      DateTime fechaFinal=(eventos[i]["fechaFinal"] as Timestamp).toDate();

      meetings.add(
        Meeting(
            nombresEventos[i],
            fechaInicio,
            fechaFinal,
            Color(eventos[i]["color"]),
            eventos[i]["todoDia"]
        )
      );
    }
    return meetings;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}

class Meeting {
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
}