import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class CineHomeScreen extends StatefulWidget {
  const CineHomeScreen({super.key});

  @override
  State<CineHomeScreen> createState() => _CineHomeScreenState();
}

class _CineHomeScreenState extends State<CineHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _peliculas = [];
  bool _isLoading = false;

  // Datos de ejemplo (en un caso real, estos vendrían de Firestore)
  final Map<String, List<Map<String, dynamic>>> _carteleraPorDia = {
    'lunes': [
      {
        'titulo': 'Duna: Parte Dos',
        'horarios': ['14:00', '17:00', '20:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BN2QyZGU4MDctYWMyOS00NjAzLTg0ODAtM2MxY2U2MTY2ODNkXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'B15'
      },
      {
        'titulo': 'Kung Fu Panda 4',
        'horarios': ['15:30', '18:00', '20:30'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BODZhNmIzNGMtYjUyYi00ZjVjLTg0MWQtMmIyZGM3NjE1MTI2XkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_.jpg',
        'clasificacion': 'A'
      }
    ],
    'martes': [
      {
        'titulo': 'Civil War',
        'horarios': ['13:30', '16:30', '19:30', '22:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BNWY0YWFmZWItZTBjMS00OGI5LWIyOTYtZGRiM2U4Y2JkNDYwXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'B'
      }
    ],
    'miercoles': [
      {
        'titulo': 'Godzilla y Kong: El nuevo imperio',
        'horarios': ['14:30', '17:30', '20:30'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BZTcxNzgwYjktNzVmNS00YWQ4LTgyYWQtODVjMzE4ZDI2OGI1XkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_.jpg',
        'clasificacion': 'B'
      },
      {
        'titulo': 'Abigail',
        'horarios': ['16:00', '19:00', '22:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MVBNZDc4YjkyYjItYjE1ZC00YzMwLTk1OTAtNDA5ZDI4Y2M5ODU5XkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'C'
      }
    ],
    'jueves': [
      {
        'titulo': 'Los tipos malos',
        'horarios': ['15:00', '17:00', '19:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BZDhkNzU0OTgtYjEzNS00MGUzLThkMWItMDk5YTM5NGY5YjU0XkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'A'
      }
    ],
    'viernes': [
      {
        'titulo': 'Challengers',
        'horarios': ['14:00', '16:30', '19:00', '21:30'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BNDYzNjZjNDktMzA3Ny00Y2M1LTlkYjktZTY0YzQwOTFlY2I0XkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_.jpg',
        'clasificacion': 'B15'
      },
      {
        'titulo': 'Tarot',
        'horarios': ['15:30', '18:00', '20:30', '23:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BNDY1M2Y0Y2ItYjVhYi00YzI4LTg5OTktODA0ZTI0MWIwYjIxXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'B15'
      }
    ],
    'sabado': [
      {
        'titulo': 'El reino del planeta de los simios',
        'horarios': ['12:00', '15:00', '18:00', '21:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BOWY0MWY1NDQtYjA2Yi00YzE0LTg0OGYtOTQ1YzE4ZDI1OTRlXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'B'
      },
      {
        'titulo': 'Furiosa: De la saga Mad Max',
        'horarios': ['13:30', '16:30', '19:30', '22:30'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BN2E1N2I0YzktYzU5Yi00Y2U5LWE1NzAtYjU1MmU5YTNjZThjXkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_.jpg',
        'clasificacion': 'B15'
      }
    ],
    'domingo': [
      {
        'titulo': 'IF',
        'horarios': ['11:00', '13:30', '16:00', '18:30'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BZTdkYTQzYjMtNjY5Yy00M2RiLTg0OTktODI0M2I0YjQ5ZGY0XkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'A'
      },
      {
        'titulo': 'Back to Black',
        'horarios': ['14:00', '16:30', '19:00'],
        'imagen': 'https://m.media-amazon.com/images/M/MV5BODQ3YmM2ZDQtYjgwNy00YzUwLTg1NjAtY2Y0YzhlN2E1OTQxXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        'clasificacion': 'B15'
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _cargarPeliculasDelDia();
  }

  Future<void> _cargarPeliculasDelDia() async {
    setState(() => _isLoading = true);

    // Simular carga desde Firestore
    await Future.delayed(const Duration(seconds: 1));

    final diaSemana = _obtenerDiaSemana(_selectedDate);
    setState(() {
      _peliculas.clear();
      _peliculas.addAll(_carteleraPorDia[diaSemana] ?? []);
      _isLoading = false;
    });
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
          // Imagen de la película
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

          // Información de la película
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y clasificación
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
                  ],
                ),

                const SizedBox(height: 12),

                // Horarios
                const Text(
                  'Horarios:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (pelicula['horarios'] as List).map((horario) {
                    return Chip(
                      label: Text(horario),
                      backgroundColor: Colors.black,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Botón de compra
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navegar a pantalla de compra
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Comprar boletos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
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