import 'package:app_cine/pantallas/pantalla_resumen.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Pantalla principal de la aplicación de cine
class PantallaPrincipalCine extends StatefulWidget {
  const PantallaPrincipalCine({super.key});

  @override
  State<PantallaPrincipalCine> createState() => _EstadoPantallaPrincipalCine();
}

class _EstadoPantallaPrincipalCine extends State<PantallaPrincipalCine> {
  DateTime _fechaSeleccionada = DateTime.now();
  final List<Map<String, dynamic>> _listadoPeliculas = [];
  bool _cargando = false;

  // Verifica si una fecha ya pasó (es anterior al día actual)
  bool _esFechaAnterior(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year < hoy.year ||
        (fecha.year == hoy.year && fecha.month < hoy.month) ||
        (fecha.year == hoy.year && fecha.month == hoy.month && fecha.day < hoy.day);
  }

  // Comprueba si una función ya pasó según su horario
  bool _esFuncionPasada(String fechaStr, String horarioStr) {
    try {
      final fecha = DateFormat('yyyy-MM-dd').parse(fechaStr);
      final partesHora = horarioStr.split(':');
      final horaFuncion = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          int.parse(partesHora[0]),
          int.parse(partesHora[1])
      );
      return horaFuncion.isBefore(DateTime.now());
    } catch (e) {
      debugPrint('Error al procesar el horario: $e');
      return false;
    }
  }

  // Obtiene las películas disponibles para la fecha seleccionada
  Future<void> _obtenerPeliculasDelDia() async {
    setState(() => _cargando = true);

    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
      debugPrint('Consultando películas para: $fechaFormateada');

      final snapshot = await FirebaseFirestore.instance
          .collection('peliculas')
          .get();

      final peliculasDisponibles = snapshot.docs.where((doc) {
        final datos = doc.data();
        final horariosPorCine = datos['horariosPorCineteca'] as Map<String, dynamic>? ?? {};

        return horariosPorCine.values.any((datosCine) {
          final fechas = _procesarFechas(datosCine['fechas']);
          return fechas.contains(fechaFormateada);
        });
      }).toList();

      setState(() {
        _listadoPeliculas.clear(); //limpia las peliculas de la fecha anterior
        _listadoPeliculas.addAll(peliculasDisponibles.map((doc) { // carga las nuevas peliculas de la fecha seleccionada
          final datos = doc.data();
          final horariosPorCine = datos['horariosPorCineteca'] as Map<String, dynamic>? ?? {};

          final cinesDisponibles = horariosPorCine.entries.where((entry) {
            final fechas = _procesarFechas(entry.value['fechas']);
            return fechas.contains(fechaFormateada);
          }).map((entry) {
            // Filtramos horarios que ya pasaron
            final horarios = (entry.value['horarios'] as List? ?? [])
                .where((horario) => !_esFuncionPasada(fechaFormateada, horario.toString()))
                .toList();

            return {
              'cineteca': entry.key,
              'horarios': horarios,
              'tieneHorarios': horarios.isNotEmpty
            };
          }).where((cine) => cine['tieneHorarios'] == true)
              .map((cine) => cine['cineteca'] as String)
              .toList();
          // constructor por default si no encuentra los datos
          return {
            'id': doc.id,
            'titulo': datos['titulo'] ?? 'Sin título',
            'imagen': datos['imagen'] ?? '',
            'clasificacion': datos['clasificacion'] ?? 'NR',
            'duracion': datos['duracion'] ?? 'Duración no disponible',
            'sinopsis': datos['sinopsis'] ?? '',
            'genero': datos['genero'] ?? '',
            'horariosPorCineteca': horariosPorCine,
            'cinesDisponibles': cinesDisponibles,
            'fechaSeleccionada': fechaFormateada,
          };
        }));
        _cargando = false;
      });
    // Si no puede acceder a FireStore
    } catch (e) {
      debugPrint('Error al cargar películas: $e');
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ups, algo salió mal: ${e.toString()}')),
        );
      }
    }
  }

  // Procesa las fechas que vienen de la base de datos
  List<String> _procesarFechas(dynamic fechasInput) {
    if (fechasInput == null) return [];
    if (fechasInput is List) {
      return fechasInput.map((e) => e.toString()).toList();
    }
    // Convierte la lista de fechas en un string
    try {
      final fechasStr = fechasInput.toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll(' ', '');
      return fechasStr.split(',');
    } catch (e) {
      debugPrint('Error al leer las fechas: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _obtenerPeliculasDelDia();
  }

  // Obtiene el nombre del día de la semana
  String _nombreDia(DateTime fecha) {
    const dias = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    return dias[fecha.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final diaSemana = _nombreDia(_fechaSeleccionada);

    return Scaffold(
      body: Column(
        children: [
          // Calendario para seleccionar fecha
          SizedBox(
            height: 300,
            child: SfCalendar(
              view: CalendarView.month,
              onTap: (detalles) {
                if (detalles.date != null && !_esFechaAnterior(detalles.date!)) {
                  setState(() {
                    _fechaSeleccionada = detalles.date!;
                  });
                  _obtenerPeliculasDelDia();
                }
              },
              initialSelectedDate: _fechaSeleccionada,
              cellBorderColor: Colors.transparent,
              todayHighlightColor: Colors.red,
              selectionDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.red, width: 2),
                shape: BoxShape.circle,
              ),
              monthViewSettings: MonthViewSettings(
                showTrailingAndLeadingDates: false,
              ),
              // Mostramos fechas pasadas en gris
              monthCellBuilder: (context, detalles) {
                final noDisponible = _esFechaAnterior(detalles.date);
                return Container(
                  decoration: BoxDecoration(
                    color: noDisponible ? Colors.grey.withOpacity(0.3) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      detalles.date.day.toString(),
                      style: TextStyle(
                        color: noDisponible ? Colors.grey : null,
                      ),
                    ),
                  ),
                );
              },
              minDate: DateTime.now(), // No permitir seleccionar fechas pasadas
            ),
          ),

          // Título con la fecha seleccionada
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Películas para el ${_fechaSeleccionada.day}/${_fechaSeleccionada.month} ($diaSemana)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Listado de películas
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _listadoPeliculas.isEmpty
                ? const Center(child: Text('No hay funciones programadas para este día'))
                : ListView.builder(
              itemCount: _listadoPeliculas.length,
              itemBuilder: (context, index) {
                final pelicula = _listadoPeliculas[index];
                return _TarjetaPelicula(pelicula: pelicula);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta que muestra la información de cada película
class _TarjetaPelicula extends StatefulWidget {
  final Map<String, dynamic> pelicula;

  const _TarjetaPelicula({required this.pelicula});

  @override
  State<_TarjetaPelicula> createState() => _EstadoTarjetaPelicula();
}

class _EstadoTarjetaPelicula extends State<_TarjetaPelicula> {
  Map<String, String?> _horariosElegidos = {};

  // Selecciona o deselecciona un horario
  void _elegirHorario(String cine, String horario) {
    setState(() {
      _horariosElegidos[cine] =
      _horariosElegidos[cine] == horario ? null : horario;
    });
  }

  // Navega a la pantalla de compra
  void _irAComprar(String cine) {
    final horario = _horariosElegidos[cine];
    if (horario != null) {
      try {
        final fechaFuncion = DateFormat('yyyy-MM-dd').parse(widget.pelicula['fechaSeleccionada']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaResumen(
              idPelicula: widget.pelicula['id'],
              titulo: widget.pelicula['titulo'],
              cineteca: cine,
              horario: horario,
              imagen: widget.pelicula['imagen'],
              fechaFuncion: fechaFuncion,
            ),
          ),
        );
      } catch (e) { // Error de procesamiento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la fecha: $e')),
        );
      }
    }
  }
  // Widget para las tarjetas de cada pelicula
  @override
  Widget build(BuildContext context) {
    final horariosPorCine = widget.pelicula['horariosPorCineteca'] as Map<String, dynamic>? ?? {};
    final cinesDisponibles = widget.pelicula['cinesDisponibles'] as List<String>? ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster de la película
          Image.network(
            widget.pelicula['imagen'],
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.movie, size: 50),
            ),
          ),

          // Información de la película
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y detalles
                Text(
                  widget.pelicula['titulo'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Clasificación: ${widget.pelicula['clasificacion']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Duración: ${widget.pelicula['duracion']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.pelicula['sinopsis'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Género: ${widget.pelicula['genero']}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),

                // Horarios por cine
                for (final cine in cinesDisponibles)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        cine,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Botones de horarios
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (horariosPorCine[cine]?['horarios'] as List? ?? []).map((horario) {
                          final horarioStr = horario.toString();
                          final seleccionado = _horariosElegidos[cine] == horarioStr;
                          return ElevatedButton(
                            onPressed: () => _elegirHorario(cine, horarioStr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: seleccionado
                                  ? _colorParaCine(cine).withOpacity(0.7)
                                  : _colorParaCine(cine),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              horarioStr,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),

                      // Botón de compra si hay horario seleccionado
                      if (_horariosElegidos[cine] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _irAComprar(cine),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _colorParaCine(cine),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Comprar para las ${_horariosElegidos[cine]}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Asigna colores diferentes a cada cine
  Color _colorParaCine(String cine) {
    switch (cine.toLowerCase()) {
      case 'cineteca nacional de las artes':
        return Colors.red[700]!;
      case 'cineteca nacional méxico':
        return Colors.blue[700]!;
      default:
        return Colors.purple[700]!;
    }
  }
}