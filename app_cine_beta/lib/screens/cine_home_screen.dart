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
        final fechas = _parsearFechas(data['fechasDisponibles']);
        debugPrint('📆 Fechas disponibles: ${fechas.join(', ')}');
        return fechas.contains(fechaFormateada);
      }).toList();

      debugPrint('🎬 Películas filtradas: ${peliculasFiltradas.length}');

      setState(() {
        _peliculas.clear();
        _peliculas.addAll(peliculasFiltradas.map((doc) {
          final data = doc.data();
          return {
            'titulo': data['titulo'] ?? 'Sin título',
            'horarios': [data['horario'] ?? '--:--'],
            'imagen': data['imagen'] ?? '',
            'clasificacion': data['clasificacion'] ?? 'NR',
            'duracion': data['duracion'] ?? 'Duración no disponible',
            'sinopsis': data['sinopsis'] ?? '',
            'salas': data['salas'] ?? 'Sala no asignada',
            'genero': data['genero'] ?? ''
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
    if (fechasInput is List) {
      return fechasInput.map((e) => e.toString()).toList();
    }

    try {
      // Intenta parsear si es un String con formato de array
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
    const dias = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'];
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
    final user = FirebaseAuth.instance.currentUser;
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
          // Calendario
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

          // Encabezado de cartelera
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

          // Lista de películas
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

class _PeliculaCard extends StatelessWidget {
  final Map<String, dynamic> pelicula;

  const _PeliculaCard({required this.pelicula});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(
            pelicula['imagen'],
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
                        pelicula['titulo'],
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
                            pelicula['clasificacion'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pelicula['duracion'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Género: ${pelicula['genero']}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Horario:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: (pelicula['horarios'] as List).map((horario) {
                    return Chip(
                      label: Text(horario.toString()), // .toString() por seguridad
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sala: ${pelicula['salas']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  pelicula['sinopsis'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Comprar boletos'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}