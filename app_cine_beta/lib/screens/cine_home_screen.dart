import 'package:app_cine/screens/resumen_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class CineHomeScreen extends StatefulWidget {
  const CineHomeScreen({super.key});

  @override
  State<CineHomeScreen> createState() => _CineHomeScreenState();
}

class _CineHomeScreenState extends State<CineHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _peliculas = [];
  bool _isLoading = false;

  Future<void> _cargarPeliculasDelDia() async {
    setState(() => _isLoading = true);

    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(_selectedDate);
      debugPrint('🔄 Buscando películas para: $fechaFormateada');

      final snapshot = await FirebaseFirestore.instance
          .collection('peliculas')
          .get();

      debugPrint('📄 Documentos totales: ${snapshot.docs.length}');

      final peliculasFiltradas = snapshot.docs.where((doc) {
        final data = doc.data();
        final horariosPorCineteca = data['horariosPorCineteca'] as Map<String, dynamic>? ?? {};

        return horariosPorCineteca.values.any((cineData) {
          final fechas = _parsearFechas(cineData['fechas']);
          return fechas.contains(fechaFormateada);
        });
      }).toList();

      debugPrint('🎬 Películas filtradas: ${peliculasFiltradas.length}');

      setState(() {
        _peliculas.clear();
        _peliculas.addAll(peliculasFiltradas.map((doc) {
          final data = doc.data();
          final horariosPorCineteca = data['horariosPorCineteca'] as Map<String, dynamic>? ?? {};

          final cinetecasDisponibles = horariosPorCineteca.entries.where((entry) {
            final fechas = _parsearFechas(entry.value['fechas']);
            return fechas.contains(fechaFormateada);
          }).map((entry) => entry.key).toList();

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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaSemana = _obtenerDiaSemana(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cineteca Nacional'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: SfCalendar(
              view: CalendarView.month,
              onTap: (calendarTapDetails) {
                if (calendarTapDetails.date != null) {
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumenScreen(
            peliculaId: widget.pelicula['id'],
            titulo: widget.pelicula['titulo'],
            cineteca: cineteca,
            horario: horario,
            imagen: widget.pelicula['imagen'],
          ),
        ),
      );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.pelicula['titulo'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.pelicula['clasificacion'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pelicula['duracion'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Género: ${widget.pelicula['genero']}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sinopsis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.pelicula['sinopsis'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

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

                      // Botón de compra para esta cineteca (solo si hay horario seleccionado)
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