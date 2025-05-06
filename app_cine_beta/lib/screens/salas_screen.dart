import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:app_cine/screens/pago_screen.dart';

class SalasScreen extends StatefulWidget {
  final String peliculaId;
  final String titulo;
  final String cineteca;
  final String horario;
  final String sala;
  final int cantidadAsientos;
  final double precioTotal;
  final DateTime fechaFuncion;

  const SalasScreen({
    super.key,
    required this.peliculaId,
    required this.titulo,
    required this.cineteca,
    required this.horario,
    required this.sala,
    required this.cantidadAsientos,
    required this.precioTotal,
    required this.fechaFuncion,
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

  Future<void> _guardarReserva() async {
    if (_asientosSeleccionados.isEmpty) {
      _mostrarSnackbar('Selecciona al menos un asiento');
      return;
    }

    if (_asientosSeleccionados.length != widget.cantidadAsientos) {
      _mostrarSnackbar('Debes seleccionar exactamente ${widget.cantidadAsientos} asiento(s)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Verificar disponibilidad de asientos (sin guardar aún)
      final asientosOcupados = await getAsientosOcupados(
        widget.peliculaId,
        widget.horario,
        widget.sala,
        widget.fechaFuncion,
      );

      final asientosConflictivos = _asientosSeleccionados
          .where((asiento) => asientosOcupados.contains(asiento))
          .toList();

      if (asientosConflictivos.isNotEmpty) {
        throw Exception('Asientos ${asientosConflictivos.join(', ')} ya están ocupados');
      }

      // 2. Preparar datos de reserva (sin guardar)
      final reservaData = {
        'peliculaId': widget.peliculaId,
        'titulo': widget.titulo,
        'cineteca': widget.cineteca,
        'horario': widget.horario,
        'sala': widget.sala,
        'asientos': _asientosSeleccionados,
        'cantidadAsientos': widget.cantidadAsientos,
        'precioTotal': widget.precioTotal,
        'fechaFuncion': DateFormat('yyyy-MM-dd').format(widget.fechaFuncion),
        'usuarioId': user.uid,
        'estado': 'pendiente_pago',
      };

      // 3. Navegar a pantalla de pago
      if (!mounted) return;
      final pagoExitoso = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => pago_screen(reservaData: reservaData),
        ),
      );

      // 4. Solo guardar si el pago fue exitoso
      if (pagoExitoso == true) {
        await FirebaseFirestore.instance.collection('reservas').add({
          ...reservaData,
          'fechaReserva': FieldValue.serverTimestamp(),
          'estado': 'completada',
        });

        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
        _mostrarSnackbar('Reserva y pago completados', isError: false);
      }

    } catch (e) {
      debugPrint('Error en reserva: $e');
      if (!mounted) return;
      _mostrarSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Función auxiliar para mostrar snackbars
  void _mostrarSnackbar(String mensaje, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<List<String>> getAsientosOcupados(
      String peliculaId,
      String horario,
      String sala,
      DateTime fechaFuncion, // Añade fecha como parámetro
      ) async {
    try {
      final fechaFormateada = DateFormat('yyyy-MM-dd').format(fechaFuncion);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .where('peliculaId', isEqualTo: peliculaId)
          .where('horario', isEqualTo: horario)
          .where('sala', isEqualTo: sala)
          .where('fechaFuncion', isEqualTo: fechaFormateada) // Nueva condición
          .get();

      return querySnapshot.docs
          .expand((doc) => List<String>.from(doc.data()['asientos'] ?? []))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo asientos ocupados: $e');
      return [];
    }
  }

  void _toggleAsiento(String asiento) {
    setState(() {
      if (_asientosSeleccionados.contains(asiento)) {
        _asientosSeleccionados.remove(asiento);
      } else {
        if (_asientosSeleccionados.length < widget.cantidadAsientos) {
          _asientosSeleccionados.add(asiento);
        } else {
          // Mostrar error si excede la cantidad permitida
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Solo puedes seleccionar ${widget.cantidadAsientos} asientos')),
          );
        }
      }
    });
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
            child: FutureBuilder<List<String>>(
              future: getAsientosOcupados(
                  widget.peliculaId, widget.horario, widget.sala, widget.fechaFuncion),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final asientosOcupados = snapshot.data ?? [];

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: 100, // 10x10 asientos
                  itemBuilder: (context, index) {
                    final fila = String.fromCharCode(65 + index ~/ 10);
                    final numero = index % 10 + 1;
                    final asiento = '$fila$numero';
                    final isOcupado = asientosOcupados.contains(asiento);
                    final isSelected = _asientosSeleccionados.contains(asiento);

                    return GestureDetector(
                      onTap: isOcupado ? null : () => _toggleAsiento(asiento),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOcupado
                              ? Colors.red.withOpacity(0.7)
                              : isSelected
                              ? Colors.green
                              : Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isOcupado
                                ? Colors.red
                                : isSelected
                                ? Colors.green[700]!
                                : Colors.blue,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            asiento,
                            style: TextStyle(
                              color: isOcupado || isSelected
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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