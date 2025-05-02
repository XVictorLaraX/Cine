import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'salas_screen.dart';

class ResumenScreen extends StatefulWidget {
  final String peliculaId;
  final String titulo;
  final String cineteca;
  final String horario;
  final String imagen;
  final DateTime fechaFuncion;

  const ResumenScreen({
    super.key,
    required this.peliculaId,
    required this.titulo,
    required this.cineteca,
    required this.horario,
    required this.imagen,
    required this.fechaFuncion,
  });

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  int _cantidadAsientos = 1;
  double _precioPorAsiento = 120.00; // Puedes obtener este valor de Firebase si es variable
  late Future<String> _salaFuture;

  @override
  void initState() {
    super.initState();
    _salaFuture = _obtenerSala();
  }

  Future<String> _obtenerSala() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('peliculas')
          .doc(widget.peliculaId)
          .get();

      final horariosPorCineteca = doc.data()?['horariosPorCineteca'] as Map<String, dynamic>? ?? {};
      final sala = horariosPorCineteca[widget.cineteca]?['salas']?[widget.horario] ?? 'Sala no asignada';
      return sala;
    } catch (e) {
      debugPrint('Error obteniendo sala: $e');
      return 'Sala no asignada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Compra'),
      ),
      body: FutureBuilder<String>(
        future: _salaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sala = snapshot.data ?? 'Sala no asignada';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen de la película
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.imagen,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 220,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(Icons.movie, size: 50),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.titulo,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.movie_filter, '${widget.cineteca}'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, 'Horario: ${widget.horario}'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.room, 'Sala: $sala'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Selección de cantidad de asientos
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cantidad de asientos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              iconSize: 30,
                              onPressed: () {
                                if (_cantidadAsientos > 1) {
                                  setState(() {
                                    _cantidadAsientos--;
                                  });
                                }
                              },
                            ),
                            Text(
                              '$_cantidadAsientos',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.green,
                              iconSize: 30,
                              onPressed: () {
                                setState(() {
                                  _cantidadAsientos++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resumen del precio
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Precio por asiento:',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '\$${_precioPorAsiento.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${(_precioPorAsiento * _cantidadAsientos).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón para seleccionar asientos
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SalasScreen(
                            peliculaId: widget.peliculaId,
                            titulo: widget.titulo,
                            cineteca: widget.cineteca,
                            horario: widget.horario,
                            sala: sala,
                            cantidadAsientos: _cantidadAsientos,
                            precioTotal: _precioPorAsiento * _cantidadAsientos,
                            fechaFuncion: widget.fechaFuncion,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Seleccionar Asientos',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}