import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalasScreen extends StatefulWidget {
  final String peliculaId;
  final String titulo;
  final String cineteca;
  final String horario;
  final String sala;
  final int cantidadAsientos;
  final double precioTotal;

  const SalasScreen({
    super.key,
    required this.peliculaId,
    required this.titulo,
    required this.cineteca,
    required this.horario,
    required this.sala,
    required this.cantidadAsientos,
    required this.precioTotal,
  });

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  final List<String> _asientosSeleccionados = [];
  bool _isLoading = false;

  // Mapeo de salas por cineteca
  final Map<String, List<List<String>>> _mapaSalas = {
    'SALA 1 CNA': _crearSala1CNA(),
    'SALA 2 Xoco': _crearSala2Xoco(),
    // Agregar más salas según sea necesario
  };

  static List<List<String>> _crearSala1CNA() {
    return [
      ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8'],
      ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8'],
      ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8'],
      ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8'],
      ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8'],
    ];
  }

  static List<List<String>> _crearSala2Xoco() {
    return [
      ['A1', 'A2', 'A3', 'A4', 'A5'],
      ['B1', 'B2', 'B3', 'B4', 'B5'],
      ['C1', 'C2', 'C3', 'C4', 'C5'],
      ['D1', 'D2', 'D3', 'D4', 'D5'],
      ['E1', 'E2', 'E3', 'E4', 'E5'],
      ['F1', 'F2', 'F3', 'F4', 'F5'],
    ];
  }

  @override
  void initState() {
    super.initState();
    // Mostrar mensaje informativo sobre la cantidad de asientos a seleccionar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona ${widget.cantidadAsientos} asiento(s)'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _toggleAsiento(String asiento) {
    setState(() {
      if (_asientosSeleccionados.contains(asiento)) {
        _asientosSeleccionados.remove(asiento);
      } else {
        if (_asientosSeleccionados.length < widget.cantidadAsientos) {
          _asientosSeleccionados.add(asiento);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solo puedes seleccionar ${widget.cantidadAsientos} asiento(s)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _guardarReserva() async {
    if (_asientosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un asiento')),
      );
      return;
    }

    if (_asientosSeleccionados.length != widget.cantidadAsientos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar exactamente ${widget.cantidadAsientos} asiento(s)'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final reserva = {
        'peliculaId': widget.peliculaId,
        'titulo': widget.titulo,
        'cineteca': widget.cineteca,
        'horario': widget.horario,
        'sala': widget.sala,
        'asientos': _asientosSeleccionados,
        'cantidadAsientos': widget.cantidadAsientos,
        'precioTotal': widget.precioTotal,
        'fecha': DateTime.now(),
        'usuarioId': user.uid,
        'estado': 'pendiente',
      };

      await FirebaseFirestore.instance.collection('reservas').add(reserva);

      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva realizada con éxito')),
      );
    } catch (e) {
      debugPrint('Error al guardar reserva: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sala = _mapaSalas[widget.sala] ?? _crearSala1CNA();
    final anchoPantalla = MediaQuery.of(context).size.width;
    final tamanoAsiento = (anchoPantalla - 40) / (sala[0].length + 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Selección de asientos - ${widget.sala}'),
      ),
      body: Column(
        children: [
          // Pantalla de cine
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            height: 30,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'PANTALLA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Asientos
          Expanded(
            child: ListView.builder(
              itemCount: sala.length,
              itemBuilder: (context, filaIndex) {
                return Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sala[filaIndex].map((asiento) {
                      final isSelected = _asientosSeleccionados.contains(asiento);
                      return GestureDetector(
                        onTap: () => _toggleAsiento(asiento),
                        child: Container(
                          width: tamanoAsiento,
                          height: tamanoAsiento,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? Colors.red[700]! : Colors.grey,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              asiento,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // Resumen y botón de compra
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Asientos: ${_asientosSeleccionados.join(', ')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${_asientosSeleccionados.length}/${widget.cantidadAsientos}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${widget.precioTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarReserva,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Confirmar Reserva',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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