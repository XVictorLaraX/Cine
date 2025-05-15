import 'package:app_cine/pantallas/resumen_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InicioCinePantalla extends StatefulWidget {
  const InicioCinePantalla({super.key});

  @override
  State<InicioCinePantalla> createState() => _InicioCinePantallaEstado();
}

class _InicioCinePantallaEstado extends State<InicioCinePantalla> {
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _peliculas = [];
  bool _isLoading = false;

  // Función para verificar si una fecha es anterior al día actual
  bool _esFechaPasada(DateTime fecha) {
    final ahora = DateTime.now();
    return fecha.year < ahora.year ||
        (fecha.year == ahora.year && fecha.month < ahora.month) ||
        (fecha.year == ahora.year && fecha.month == ahora.month && fecha.day < ahora.day);
  }

  // Función para verificar si un horario ya pasó
  bool _esHorarioPasado(String fechaStr, String horarioStr) {
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
      debugPrint('Error al parsear horario: $e');
      return false;
    }
  }

  Future<void> _cargarPeliculasDelDia() async {
    setState(() => _isLoading = true);

    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(_selectedDate);
      debugPrint('Buscando películas para: $fechaFormateada');

      final snapshot = await FirebaseFirestore.instance
          .collection('peliculas')
          .get();

      final peliculasFiltradas = snapshot.docs.where((doc) {
        final data = doc.data();
        final horariosPorCineteca = data['horariosPorCineteca'] as Map<String, dynamic>? ?? {};

        return horariosPorCineteca.values.any((cineData) {
          final fechas = _parsearFechas(cineData['fechas']);
          return fechas.contains(fechaFormateada);
        });
      }).toList();

      setState(() {
        _peliculas.clear();
        _peliculas.addAll(peliculasFiltradas.map((doc) {
          final data = doc.data();
          final horariosPorCineteca = data['horariosPorCineteca'] as Map<String, dynamic>? ?? {};

          final cinetecasDisponibles = horariosPorCineteca.entries.where((entry) {
            final fechas = _parsearFechas(entry.value['fechas']);
            return fechas.contains(fechaFormateada);
          }).map((entry) {
            // Filtrar horarios que ya pasaron
            final horarios = (entry.value['horarios'] as List? ?? [])
                .where((horario) => !_esHorarioPasado(fechaFormateada, horario.toString()))
                .toList();

            return {
              'cineteca': entry.key,
              'horarios': horarios,
              'tieneHorariosDisponibles': horarios.isNotEmpty
            };
          }).where((cine) => cine['tieneHorariosDisponibles'] == true)
              .map((cine) => cine['cineteca'] as String)
              .toList();

          return {
            'id': doc.id,
            'titulo': data['titulo'] ?? 'Sin título',
            'imagen': data['imagen'] ?? '',
            'clasificacion': data['clasificacion'] ?? 'NR',
            'duracion': data['duracion'] ?? 'Duración no disponible',
            'sinopsis': data['sinopsis'] ?? '',
            'genero': data['genero'] ?? '',
            'horariosPorCineteca': horariosPorCineteca,
            'cinetecasDisponibles': cinetecasDisponibles,
            'fechaSeleccionada': fechaFormateada,
          };
        }));
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<String> _parsearFechas(dynamic fechasInput) {
    if (fechasInput == null) return [];
    if (fechasInput is List) {
      return fechasInput.map((e) => e.toString()).toList();
    }

    try {
      final fechasStr = fechasInput.toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll(' ', '');
      return fechasStr.split(',');
    } catch (e) {
      debugPrint('Error parseando fechas: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarPeliculasDelDia();
  }

  String _obtenerDiaSemana(DateTime fecha) {
    const dias = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    return dias[fecha.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final diaSemana = _obtenerDiaSemana(_selectedDate);

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: SfCalendar(
              view: CalendarView.month,
              onTap: (calendarTapDetails) {
                if (calendarTapDetails.date != null && !_esFechaPasada(calendarTapDetails.date!)) {
                  setState(() {
                    _selectedDate = calendarTapDetails.date!;
                  });
                  _cargarPeliculasDelDia();
                }
              },
              initialSelectedDate: _selectedDate,
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
              // Solución alternativa para versiones que no soportan blackoutDates
              monthCellBuilder: (context, details) {
                final isDisabled = _esFechaPasada(details.date);
                return Container(
                  decoration: BoxDecoration(
                    color: isDisabled ? Colors.grey.withOpacity(0.3) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      details.date.day.toString(),
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                  ),
                );
              },
              minDate: DateTime.now(), // Previene selección de fechas pasadas
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Cartelera para el ${_selectedDate.day}/${_selectedDate.month} ($diaSemana)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _peliculas.isEmpty
                ? const Center(child: Text('No hay películas programadas para este día'))
                : ListView.builder(
              itemCount: _peliculas.length,
              itemBuilder: (context, index) {
                final pelicula = _peliculas[index];
                return _PeliculaCard(pelicula: pelicula);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeliculaCard extends StatefulWidget {
  final Map<String, dynamic> pelicula;

  const _PeliculaCard({required this.pelicula});

  @override
  State<_PeliculaCard> createState() => __PeliculaCardState();
}

class __PeliculaCardState extends State<_PeliculaCard> {
  Map<String, String?> _horariosSeleccionados = {};

  void _seleccionarHorario(String cineteca, String horario) {
    setState(() {
      _horariosSeleccionados[cineteca] =
      _horariosSeleccionados[cineteca] == horario ? null : horario;
    });
  }

  void _comprarBoletos(String cineteca) {
    final horario = _horariosSeleccionados[cineteca];
    if (horario != null) {
      try {
        final fechaFuncion = DateFormat('yyyy-MM-dd').parse(widget.pelicula['fechaSeleccionada']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResumenPantalla(
              peliculaId: widget.pelicula['id'],
              titulo: widget.pelicula['titulo'],
              cineteca: cineteca,
              horario: horario,
              imagen: widget.pelicula['imagen'],
              fechaFuncion: fechaFuncion,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la fecha: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horariosPorCineteca = widget.pelicula['horariosPorCineteca'] as Map<String, dynamic>? ?? {};
    final cinetecasDisponibles = widget.pelicula['cinetecasDisponibles'] as List<String>? ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (resto del código de la tarjeta de película se mantiene igual)
                // Sección de horarios por cineteca
                for (final cineteca in cinetecasDisponibles)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        cineteca,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (horariosPorCineteca[cineteca]?['horarios'] as List? ?? []).map((horario) {
                          final horarioStr = horario.toString();
                          final isSelected = _horariosSeleccionados[cineteca] == horarioStr;
                          return ElevatedButton(
                            onPressed: () => _seleccionarHorario(cineteca, horarioStr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? _getColorForCineteca(cineteca).withOpacity(0.7)
                                  : _getColorForCineteca(cineteca),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              horarioStr,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_horariosSeleccionados[cineteca] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _comprarBoletos(cineteca),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getColorForCineteca(cineteca),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Comprar boletos para las ${_horariosSeleccionados[cineteca]}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCineteca(String cineteca) {
    switch (cineteca.toLowerCase()) {
      case 'cineteca nacional de las artes':
        return Colors.red[700]!;
      case 'cineteca nacional méxico':
        return Colors.blue[700]!;
      default:
        return Colors.purple[700]!;
    }
  }
}